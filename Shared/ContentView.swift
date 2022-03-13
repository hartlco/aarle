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
    @EnvironmentObject var linkViewStore: LinkViewStore

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
            if linkViewStore.isLoading {
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
            if linkViewStore.didLoad(listType: listType) {
                return
            }
            linkViewStore.send(.load(listType))
        }
    }

    private var list: some View {
        List {
            ForEach(linkViewStore.links(for: listType)) { link in
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
                        linkViewStore.send(.delete(link))
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            if linkViewStore.canLoadMore(for: listType) {
                HStack {
                    Spacer()
                    Button {
                        guard let lastLink = linkViewStore.links(for: listType).last else { return }
                        linkViewStore.send(.loadMoreIfNeeded(listType, lastLink))
                    } label: {
                        Label("Load More", systemImage: "ellipsis")
                    }.buttonStyle(BorderlessButtonStyle()).padding()
                    Spacer()
                }
            }
        }
        .searchable(
            text: Binding(
                get: { linkViewStore.searchText(for: listType) },
                set: { linkViewStore.send(.changeSearchText($0, listType: listType)) }
            )
        )
        .onSubmit(of: .search) {
            linkViewStore.send(.search(listType))
        }
        .refreshable {
            linkViewStore.send(.load(listType))
        }
        .listStyle(PlainListStyle())
    }
}
