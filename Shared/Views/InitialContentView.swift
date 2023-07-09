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

    @EnvironmentObject var overallAppState: OverallAppState

    @Binding var navigationState: NavigationState
    var tagState: TagState

    var body: some View {
        NavigationSplitView(
            columnVisibility: $columnVisibility
        ) {
            sidebar
        } content: {
            switch navigationState.selectedListType {
            case .all:
                ContentView(
                    title: "Links",
                    listType: .all,
                    presentationMode: .list,
                    navigationState: $navigationState,
                    listState: overallAppState.listState,
                    archiveState: overallAppState.archiveState
                )
            case let .tagScoped(tag):
                ContentView(
                    title: tag.name,
                    listType: .tagScoped(tag),
                    presentationMode: .list,
                    navigationState: $navigationState,
                    listState: overallAppState.listState,
                    archiveState: overallAppState.archiveState
                )
            case .downloaded:
                DownloadedListView(
                    archiveState: overallAppState.archiveState,
                    selectedArchiveLink: $navigationState.selectedArchiveLink
                )
            case .tags:
                List(tagState.tags, selection: $navigationState.selectedTag) { tag in
                    NavigationLink(value: tag) {
                        TagView(
                            tag: tag,
                            isFavorite: tagState.isTagFavorite(tag: tag),
                            favorite: {
                                tagState.toggleFavorite(tag: tag)
                            }
                        )
                    }
                }
            case .none:
                Text("Select")
            }
        } detail: {
            NavigationStack(path: $navigationState.detailNavigationStack) {
                detailView
                    .navigationDestination(for: Link.self) { navigationLink in
                        ItemDetailView(
                            link: navigationLink,
                            navigationState: overallAppState.navigationState
                        )
                    }
            }
        }
    }

    private var sidebar: some View {
        SidebarView(
            navigationState: $navigationState,
            tagState: tagState,
            settingsState: overallAppState.settingsState
        )
        .navigationTitle("aarle")
        .alert(isPresented: $overallAppState.listState.showLoadingError) {
            networkingAlert
        }
        .alert(
            isPresented: $overallAppState.tagState.showLoadingError
        ) {
            networkingAlert
        }
    }

    @ViewBuilder
    private var detailView: some View {
        if let selectedTag = navigationState.selectedTag {
            tagListContentView(selectedTag: selectedTag)
        } else if let selectedLink = navigationState.selectedLink {
            ItemDetailView(
                link: selectedLink,
                navigationState: overallAppState.navigationState
            )
        }
    }

    @ViewBuilder
    private func tagListContentView(selectedTag: Tag) -> some View {
        ContentView(
            title: selectedTag.name,
            listType: .tagScoped(selectedTag),
            presentationMode: .detail,
            navigationState: $navigationState,
            listState: overallAppState.listState,
            archiveState: overallAppState.archiveState
        )
    }

    private var networkingAlert: Alert {
        Alert(
            title: Text("Networking Error"),
            message: Text("Please try again.")
        )
    }
}
