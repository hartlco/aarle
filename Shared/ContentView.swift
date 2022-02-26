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
    @EnvironmentObject var appViewStore: AppViewStore
    @EnvironmentObject var tagViewStore: TagViewStore
    @EnvironmentObject var linkStore: LinkViewStore

    private let pasteboard: Pasteboard
    private let title: String
    private let listType: ListType

    init(
        title: String,
        pasteboard: Pasteboard = DefaultPasteboard(),
        listType: ListType
    ) {
        self.title = title
        self.pasteboard = pasteboard
        self.listType = listType
    }

    var body: some View {
        // TODO: Add empty state if no data available, reload button
        // TODO: allow opening HTTPS links
        ZStack {
            list
            if linkStore.isLoading {
                VStack {
                    ProgressView()
                        .padding()
                    Spacer()

                }
            }
        }
        .sheet(item: appViewStore.binding(get: \.presentedEditLink, send: { .setEditLink($0) })) { link in
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
                    appViewStore.send(.showAddView)
                } label: {
                    Label("Add", systemImage: "plus")
                }
#if os(iOS)
                .sheet(
                    isPresented: appViewStore.binding(get: \.showsAddView, send: { .setShowAddView($0 )}),
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
            if linkStore.didLoad(listType: listType) {
                return
            }
            linkStore.send(.load(listType))
        }
    }

    private var list: some View {
        List {
            ForEach(linkStore.links(for: listType)) { link in
                NavigationLink(
                    destination: ItemDetailView(
                        link: link
                    ),
                    tag: link.id,
                    selection: appViewStore.binding(get: \.selectedLinkID, send: { .setSelectedLinkID($0) }),
                    label: { LinkItemView(link: link) }
                ).contextMenu {
                    Button("Edit", action: { appViewStore.send(.showEditLink(link)) })
                    Button("Copy URL", action: { pasteboard.copyToPasteboard(string: link.url.absoluteString) })
                    Button(role: .destructive) {
                        linkStore.send(.delete(link))
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            if linkStore.canLoadMore(for: listType) {
                HStack {
                    Spacer()
                    Button {
                        guard let lastLink = linkStore.links(for: listType).last else { return }
                        linkStore.send(.loadMoreIfNeeded(listType, lastLink))
                    } label: {
                        Label("Load More", systemImage: "ellipsis")
                    }.buttonStyle(BorderlessButtonStyle()).padding()
                    Spacer()
                }
            }
        }
        .searchable(
            text: Binding(
                get: { linkStore.searchText(for: listType) },
                set: { linkStore.send(.changeSearchText($0, listType: listType)) }
            )
        )
        .onSubmit(of: .search) {
            linkStore.send(.search(listType))
        }
        .refreshable {
            linkStore.send(.load(listType))
        }
        .listStyle(PlainListStyle())
    }
}
