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

struct ContentView: View {
    @EnvironmentObject var archiveViewStore: ArchiveViewStore
    @EnvironmentObject var overallAppState: OverallAppState

    @State var searchText = ""
    private let pasteboard = DefaultPasteboard()

    let title: String
    let listType: ListType
    @ObservedObject var navigationState: NavigationState

    var body: some View {
        // TODO: Add empty state if no data available, reload button
        ZStack {
            list
            if overallAppState.isLoading {
                VStack {
                    ProgressView()
                        .padding()
                    Spacer()
                }
            }
        }
        #if os(iOS)
        .sheet(item: $overallAppState.presentedEditLink) { link in
            NavigationView {
                LinkEditView(link: link, showCancelButton: true)
            }
        }
        #endif
        .toolbar {
            ToolbarItem {
                Button {
                    overallAppState.showsAddView = true
                } label: {
                    Label("Add", systemImage: "plus")
                }
                #if os(iOS)
                .sheet(
                    isPresented: $overallAppState.showsAddView,
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
            if overallAppState.didLoad(listType: listType) {
                return
            }
            Task {
                await overallAppState.loadSearch(for: listType)
            }
        }
        .id(listType)
    }

    private var list: some View {
        List(selection: $navigationState.selectedLink) {
            ForEach(overallAppState.links(for: listType)) { link in
                NavigationLink(value: link) {
                    LinkItemView(link: link)
                }.contextMenu {
                    Button("Edit") {
                        editAction(link: link)
                    }
                    Button("Copy URL", action: { pasteboard.copyToPasteboard(string: link.url.absoluteString) })
                    Button(role: .destructive) {
                        Task {
                            await overallAppState.delete(link: link)
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    Button("Download") {
                        archiveViewStore.send(.archiveLink(link: link))
                    }
                }
            }
            if overallAppState.canLoadMore(for: listType) {
                HStack {
                    Spacer()
                    Button {
                        guard let lastLink = overallAppState.links(for: listType).last else { return }
                        Task {
                            await overallAppState.loadMoreIfNeeded(type: listType, link: lastLink)
                        }
                    } label: {
                        Label("Load More", systemImage: "ellipsis")
                    }.buttonStyle(BorderlessButtonStyle()).padding()
                    Spacer()
                }
            }
        }
        .navigationDestination(for: Link.self) { link in
            Text(link.url.absoluteString)
        }
        .searchable(text: $searchText)
        .onSubmit(of: .search) {
            overallAppState.setSearchText(text: searchText, for: listType)
            Task {
                await overallAppState.loadSearch(for: listType)
            }
        }
        .refreshable {
            Task {
                await overallAppState.loadSearch(for: listType)
            }
        }
        .listStyle(PlainListStyle())
    }

    private func editAction(link: Link) {
        overallAppState.presentedEditLink = link
        #if os(macOS)
            WindowRoutes.editLink.open()
        #endif
    }
}
