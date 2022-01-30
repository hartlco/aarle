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
                        guard let lastLink = linkStore.links.last else { return }
                        linkStore.reduce(.loadMoreIfNeeded(lastLink))
                    } label: {
                        Label("Load More", systemImage: "ellipsis")
                    }.buttonStyle(BorderlessButtonStyle()).padding()
                    Spacer()
                }
            }
        }
        .searchable(text: linkStore.searchText)
        .onSubmit(of: .search) {
            linkStore.reduce(.search)
        }
        // TODO: Add macOS shortcut / menu item
        .refreshable {
            linkStore.reduce(.load)
        }
        .listStyle(PlainListStyle())
        // TODO: Move into store
        .sheet(item: $showingEditLink) { link in
            LinkEditView(link: link, linkStore: linkStore, showCancelButton: true)
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
            linkStore.reduce(.load)
        }
    }
}
