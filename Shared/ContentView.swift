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
    @EnvironmentObject var appStore: AppStore
    @EnvironmentObject var tagStore: TagStore
    @EnvironmentObject var linkStore: LinkStore

    private let pasteboard: Pasteboard
    private let title: String

    init(
        title: String,
        pasteboard: Pasteboard = DefaultPasteboard()
    ) {
        self.title = title
        self.pasteboard = pasteboard
    }

    var body: some View {
        List(selection: appStore.selectedLink) {
            ForEach(linkStore.links) { link in
                NavigationLink(
                    destination: ItemDetailView(
                        link: link
                    ),
                    tag: link,
                    selection: appStore.selectedLink,
                    label: { LinkItemView(link: link) }
                ).contextMenu {
                    Button("Edit", action: { appStore.reduce(.showEditLink(link)) })
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
        .refreshable {
            linkStore.reduce(.load)
        }
        .listStyle(PlainListStyle())
        .sheet(item: appStore.presentedEditLink) { link in
#if os(macOS)
            LinkEditView(link: link, showCancelButton: true)
#elseif os(iOS)
            NavigationView {
                LinkEditView(link: link, showCancelButton: true)
            }
#endif
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
                        LinkAddView()
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
