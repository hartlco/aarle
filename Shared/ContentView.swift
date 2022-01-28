//
//  ContentView.swift
//  Shared
//
//  Created by martinhartl on 02.01.22.
//

import SwiftUI
import SwiftJWT
import SwiftUIX
import WebKit

struct ContentView: View {
    @State var settingsField = ""
    // TODO: Add to AppState
    @State var showingEditLink: Link?

    @EnvironmentObject var appStore: AppStore
    @EnvironmentObject var tagStore: TagStore

    @ObservedObject var linkStore: LinkStore

    private let pasteboard: Pasteboard
    private let title: String

    init(
        title: String,
        linkStore: LinkStore,
        pasteboard: Pasteboard = DefaultPasteboard()
    ) {
        self.title = title
        self.linkStore = linkStore
        self.pasteboard = pasteboard
    }

    var body: some View {
        List(selection: appStore.selectedLink) {
            ForEach(linkStore.links) { link in
                NavigationLink(
                    destination: ItemDetailView(
                        link: link,
                        linkStore: linkStore
                    ),
                    tag: link,
                    selection: appStore.selectedLink,
                    label: { LinkItemView(link: link) }
                )
                .contextMenu {
                    Button("Edit", action: { showingEditLink = link })
                    Button("Copy URL", action: { pasteboard.copyToPasteboard(string: link.url.absoluteString) })
                    Button(role: .destructive) {
                        Task {
                            try await linkStore.delete(link: link)
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            if linkStore.canLoadMore {
                HStack {
                    Spacer()
                    Button {
                        Task {
                            do {
                                guard let lastLink = linkStore.links.last else { return }
                                try await linkStore.loadMoreIfNeeded(link: lastLink)
                            } catch {
                                print(error)
                            }
                        }
                    } label: {
                        Label("Load More", systemImage: "ellipsis")
                    }.buttonStyle(BorderlessButtonStyle()).padding()
                    Spacer()
                }
            }
        }
        // TODO: Add macOS shortcut / menu item
        .refreshable {
            try? await linkStore.load()
        }
        .listStyle(PlainListStyle())
        // TODO: Move into store
        .popover(item: $showingEditLink) { link in
            LinkEditView(link: link, linkStore: linkStore)
        }
        .toolbar {
            ToolbarItem {
                Button {
                    appStore.reduce(.showAddView)
                } label: {
                    Label("Add", systemImage: "plus")
                }
#if os(iOS)
                .sheet(
                    isPresented: appStore.showsAddView,
                    onDismiss: nil,
                    content: {
                        LinkAddView(
                            linkStore: linkStore
                        )
                    }
                )
#endif
            }
        }
        .navigationTitle(title)
        .onAppear {
            if !linkStore.links.isEmpty {
                return
            }
            Task {
                do {
                    try await linkStore.load()
                } catch let error {
                    print(error)
                }
            }
        }
    }

    private var navigationBarItemPlacement: ToolbarItemPlacement {
        #if os(macOS)
        return .automatic
        #else
        return .navigationBarTrailing
        #endif
    }
}
