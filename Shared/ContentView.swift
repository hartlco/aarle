//
//  ContentView.swift
//  Shared
//
//  Created by martinhartl on 02.01.22.
//

import SwiftUI
import WebKit
import Types
import Navigation
import List
import Archive

struct ContentView: View {
    enum PresentationMode {
        case list
        case detail
    }

    @State var searchText = ""
    private let pasteboard = DefaultPasteboard()

    let title: String
    let listType: ListType
    let presentationMode: PresentationMode

    @Bindable var navigationState: NavigationState
    var listState: ListState
    var archiveState: ArchiveState
    var overallAppState: OverallAppState

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
                LinkEditView(editState: overallAppState.editState, showCancelButton: true)
            }
            .onAppear { overallAppState.editState.load(link: link) }
        }
        #endif
        .toolbar {
            ToolbarItem {
                Button {
                    navigationState.showsAddView = true
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }
        }
        #if os(iOS)
        .sheet(
            isPresented: $navigationState.showsAddView,
            onDismiss: nil,
            content: {
                LinkAddView(overallAppState: overallAppState)
            }
        )
        #endif
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
        presentationAwareList {
            ForEach(listState.links(for: listType)) { link in
                NavigationLink(value: DetailNavigationDestination.link(link)) {
                    LinkItemView(link: link)
                }
                .swipeActions(edge: .trailing) {
                    if link.unread {
                        Button {
                            Task {
                                await overallAppState.markLinkAsRead(link: link)
                                await listState.loadSearch(for: listType)
                            }
                        } label: {
                            Label("Mark as Read", systemImage: "checkmark.circle")
                        }
                        .tint(.green)
                    } else {
                        Button {
                            Task {
                                await overallAppState.markLinkAsUnread(link: link)
                                await listState.loadSearch(for: listType)
                            }
                        } label: {
                            Label("Mark as Unread", systemImage: "circle")
                        }
                        .tint(.blue)
                    }
                }
                .contextMenu {
                    Button {
                        editAction(link: link)
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }

                    Divider()

                    if link.unread {
                        Button {
                            Task {
                                await overallAppState.markLinkAsRead(link: link)
                                await listState.loadSearch(for: listType)
                            }
                        } label: {
                            Label("Mark as Read", systemImage: "checkmark.circle")
                        }
                    } else {
                        Button {
                            Task {
                                await overallAppState.markLinkAsUnread(link: link)
                                await listState.loadSearch(for: listType)
                            }
                        } label: {
                            Label("Mark as Unread", systemImage: "circle")
                        }
                    }

                    Divider()

                    Button {
                        pasteboard.copyToPasteboard(string: link.url.absoluteString)
                    } label: {
                        Label("Copy URL", systemImage: "doc.on.clipboard")
                    }

                    Divider()

                    Button(role: .destructive) {
                        Task {
                            await listState.delete(link: link)
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            if listState.canLoadMore(for: listType) {
                HStack {
                    Spacer()
                    Label("Loading More", systemImage: "ellipsis")
                        .font(.body.weight(.medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                }.onAppear {
                    guard let lastLink = listState.links(for: listType).last else { return }
                    Task {
                        await listState.loadMoreIfNeeded(type: listType, link: lastLink)
                    }
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

    @ViewBuilder
    private func presentationAwareList(@ViewBuilder content: () -> some View) -> some View {
        switch presentationMode {
        case .detail:
            List(content: content)
        case .list:
            List(selection: $navigationState.selectedDetailDestination, content: content)
        }
    }

    private func editAction(link: Types.Link) {
        navigationState.presentedEditLink = link
    }
}
