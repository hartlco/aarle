//
//  ContentView.swift
//  Shared
//
//  Created by martinhartl on 02.01.22.
//

import SwiftJWT
import SwiftUI
import SwiftUIX
import WebKit
import Types
import Navigation
import List
import Archive

struct ContentView: View {
    @State var searchText = ""
    private let pasteboard = DefaultPasteboard()

    let title: String
    let listType: ListType
    @ObservedObject var navigationState: NavigationState
    @ObservedObject var listState: ListState
    @ObservedObject var archiveState: ArchiveState

    var body: some View {
        // TODO: Add empty state if no data available, reload button
        ZStack {
            list
            if listState.isLoading {
                VStack {
                    ProgressView()
                        .padding()
                    Spacer()
                }
            }
        }
        #if os(iOS)
        .sheet(item: $navigationState.presentedEditLink) { link in
            NavigationView {
                LinkEditView(link: link, showCancelButton: true)
            }
        }
        #endif
        .toolbar {
            ToolbarItem {
                Button {
                    navigationState.showsAddView = true
                } label: {
                    Label("Add", systemImage: "plus")
                }
                #if os(iOS)
                .sheet(
                    isPresented: $navigationState.showsAddView,
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
            if listState.didLoad(listType: listType) {
                return
            }
            Task {
                await listState.loadSearch(for: listType)
            }
        }
        .id(listType)
    }

    private var list: some View {
        List(selection: $navigationState.selectedLink) {
            ForEach(listState.links(for: listType)) { link in
                NavigationLink(value: link) {
                    LinkItemView(link: link)
                }.contextMenu {
                    Button("Edit") {
                        editAction(link: link)
                    }
                    Button("Copy URL", action: { pasteboard.copyToPasteboard(string: link.url.absoluteString) })
                    Button(role: .destructive) {
                        Task {
                            await listState.delete(link: link)
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    Button("Download") {
                        Task {
                            await archiveState.archiveLink(link: link)
                        }
                    }
                }
            }
            if listState.canLoadMore(for: listType) {
                HStack {
                    Spacer()
                    Button {
                        guard let lastLink = listState.links(for: listType).last else { return }
                        Task {
                            await listState.loadMoreIfNeeded(type: listType, link: lastLink)
                        }
                    } label: {
                        Label("Load More", systemImage: "ellipsis")
                    }.buttonStyle(BorderlessButtonStyle()).padding()
                    Spacer()
                }
            }
        }
        .searchable(text: $searchText)
        .onSubmit(of: .search) {
            listState.setSearchText(text: searchText, for: listType)
            Task {
                await listState.loadSearch(for: listType)
            }
        }
        .refreshable {
            Task {
                await listState.loadSearch(for: listType)
            }
        }
        .listStyle(PlainListStyle())
    }

    private func editAction(link: Types.Link) {
        navigationState.presentedEditLink = link
    }
}
