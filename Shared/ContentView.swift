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
    @State var showsAddView = false
    @State var settingsField = ""
    @State var showingEditLink: Link?
    @Binding var appState: AppState

    @ObservedObject var linkStore: LinkStore
    @ObservedObject var tagStore: TagStore

    private let pasteboard: Pasteboard
    private let title: String

    init(
        title: String,
        linkStore: LinkStore,
        tagStore: TagStore,
        pasteboard: Pasteboard = DefaultPasteboard(),
        appState: Binding<AppState>
    ) {
        self.title = title
        self.linkStore = linkStore
        self.tagStore = tagStore
        self.pasteboard = pasteboard
        self._appState = appState
    }

    var body: some View {
        List(selection: $appState.selectedLink) {
            ForEach(linkStore.links) { link in
                NavigationLink(
                    destination: ItemDetailView(
                        link: link,
                        linkStore: linkStore,
                        tagStore: tagStore,
                        appState: $appState
                    ),
                    tag: link,
                    selection: $appState.selectedLink,
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
        .popover(item: $showingEditLink) { link in
            LinkEditView(link: link, linkStore: linkStore, tagStore: tagStore)
        }
        .toolbar {
            ToolbarItem {
                Button {
                    showsAddView = true
                } label: {
                    Label("Add", systemImage: "plus")
                }
                .sheet(
                    isPresented: $showsAddView,
                    onDismiss: nil,
                    content: {
                        LinkAddView(
                            linkStore: linkStore,
                            tagStore: tagStore
                        )
                    }
                )
            }
        }
        .navigationTitle(title)
        .task {
            do {
                try await linkStore.load()
            } catch let error {
                print(error)
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
