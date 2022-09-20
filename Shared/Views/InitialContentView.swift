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

struct InitialContentView: View {
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    @EnvironmentObject var overallAppState: OverallAppState

    @ObservedObject var navigationState: NavigationState
    @ObservedObject var tagState: TagState

    var body: some View {
        NavigationSplitView(
            columnVisibility: $columnVisibility
        ) {
            sidebar
        } content: {
            switch navigationState.selectedListType {
            case .all:
                ContentView(title: "Links", listType: .all, navigationState: navigationState, listState: overallAppState.listState)
            case let .tagScoped(tag):
                ContentView(title: tag.name, listType: .tagScoped(tag), navigationState: navigationState, listState: overallAppState.listState)
            case .downloaded:
                DownloadedListView(
                    archiveState: overallAppState.archiveState,
                    selectedArchiveLink: $overallAppState.navigationState.selectedArchiveLink)
            #if os(iOS)
                case .none:
                    Text("Select")
            #endif
            }
        } detail: {
            switch navigationState.selectedListType {
            case .downloaded:
                if let archiveLink = overallAppState.navigationState.selectedArchiveLink {
                    DataWebView(archiveLink: archiveLink)
                } else {
                    Text("Select a archive")
                }
            default:
                if let link = navigationState.selectedLink {
                    ItemDetailView(
                        link: link,
                        navigationState: overallAppState.navigationState
                    )
                } else {
                    Text("Select a link")
                }
            }
        }
    }

    private var sidebar: some View {
        SidebarView(
            navigationState: navigationState,
            tagState: tagState,
            settingsState: overallAppState.settingsState
        )
        .navigationTitle("aarle")
        .alert(isPresented: $overallAppState.showLoadingError) {
            networkingAlert
        }
        .alert(
            isPresented: $overallAppState.tagState.showLoadingError
        ) {
            networkingAlert
        }
    }

    private var networkingAlert: Alert {
        Alert(
            title: Text("Networking Error"),
            message: Text("Please try again.")
        )
    }
}
