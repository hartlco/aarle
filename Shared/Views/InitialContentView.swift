//
//  InitialContentView.swift
//  Aarlo
//
//  Created by martinhartl on 12.01.22.
//

import Introspect
import SwiftUI
import Types
import Settings
import Navigation
import Tag

struct InitialContentView: View {
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    @Environment(OverallAppState.self) private var overallAppState

    var body: some View {
        @Bindable var overallAppState = overallAppState
        NavigationSplitView(
            columnVisibility: $columnVisibility
        ) {
            SidebarView()
            .navigationTitle("aarle")
            .alert(isPresented: $overallAppState.listState.showLoadingError) {
                networkingAlert
            }
            .alert(
                isPresented: $overallAppState.tagState.showLoadingError
            ) {
                networkingAlert
            }
        } content: {
            switch overallAppState.navigationState.selectedListType {
            case .all:
                ContentView(
                    title: "Links",
                    listType: .all,
                    presentationMode: .list,
                    navigationState: overallAppState.navigationState,
                    listState: overallAppState.listState,
                    archiveState: overallAppState.archiveState, 
                    overallAppState: overallAppState
                )
            case let .tagScoped(tag):
                ContentView(
                    title: tag.name,
                    listType: .tagScoped(tag),
                    presentationMode: .list,
                    navigationState: overallAppState.navigationState,
                    listState: overallAppState.listState,
                    archiveState: overallAppState.archiveState, 
                    overallAppState: overallAppState
                )
            case .downloaded:
                DownloadedListView(
                    archiveState: overallAppState.archiveState,
                    navigationState: overallAppState.navigationState
                )
            case .tags:
                List(overallAppState.tagState.tags, selection: $overallAppState.navigationState.selectedDetailDestination) { tag in
                    NavigationLink(value: DetailNavigationDestination.tag(tag)) {
                        TagView(
                            tag: tag,
                            isFavorite: overallAppState.tagState.isTagFavorite(tag: tag),
                            favorite: {
                                overallAppState.tagState.toggleFavorite(tag: tag)
                            }
                        )
                    }
                }
            case .none:
                Text("Select")
            }
        } detail: {
            NavigationStack(path: $overallAppState.navigationState.detailNavigationStack) {
                detailView
                    .navigationDestination(for: DetailNavigationDestination.self) { navigationLink in
                        switch navigationLink {
                        case .link(let link):
                            ItemDetailView(
                                link: link,
                                overallAppState: overallAppState
                            )
                        default:
                            Text("Empty")
                        }
                    }
            }
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch overallAppState.navigationState.selectedDetailDestination {
        case .link(let link):
            ItemDetailView(
                link: link,
                overallAppState: overallAppState
            )
        case .archiveLink(let archiveLink):
            DataWebView(archiveLink: archiveLink)
                .toolbar {
                    ToolbarItem {
                        Menu {
                            ForEach(NSSharingService.sharingServices(forItems: [archiveLink.url]), id: \.title) { service in
                                Button(action: { service.perform(withItems: [archiveLink.url]) }) {
                                    Image(nsImage: service.image)
                                    Text(service.title)
                                }
                            }
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                    }
                }
        case .tag(let tag):
            tagListContentView(selectedTag: tag)
        case .empty, .none:
            EmptyDetailView()
        }
    }

    @ViewBuilder
    private func tagListContentView(selectedTag: Tag) -> some View {
        ContentView(
            title: selectedTag.name,
            listType: .tagScoped(selectedTag),
            presentationMode: .detail,
            navigationState: overallAppState.navigationState,
            listState: overallAppState.listState,
            archiveState: overallAppState.archiveState, 
            overallAppState: overallAppState
        )
    }

    private var networkingAlert: Alert {
        Alert(
            title: Text("Networking Error"),
            message: Text("Please try again.")
        )
    }
}
