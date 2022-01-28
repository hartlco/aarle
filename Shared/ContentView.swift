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

    @ObservedObject var linkStore: LinkStore
    @ObservedObject var tagStore: TagStore

    private let pasteboard: Pasteboard
    private let title: String

    init(
        title: String,
        linkStore: LinkStore,
        tagStore: TagStore,
        pasteboard: Pasteboard = DefaultPasteboard()
    ) {
        self.title = title
        self.linkStore = linkStore
        self.tagStore = tagStore
        self.pasteboard = pasteboard
    }

    var body: some View {
        List(selection: appStore.selectedLink) {
            ForEach(linkStore.links) { link in
                NavigationLink(
                    destination: ItemDetailView(
                        link: link,
                        linkStore: linkStore,
                        tagStore: tagStore
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
            LinkEditView(link: link, linkStore: linkStore, tagStore: tagStore)
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
                            linkStore: linkStore,
                            tagStore: tagStore
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
