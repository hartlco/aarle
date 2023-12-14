//
//  SidebarView.swift
//  Aarlo
//
//  Created by martinhartl on 07.01.22.
//

import SwiftUI
import SwiftUIX
import Types
import Settings
import Navigation
import Tag

struct SidebarView: View {
    @Environment(OverallAppState.self) private var overallAppState

    var body: some View {
        @Bindable var overallAppState = overallAppState
        List(
            selection: $overallAppState.navigationState.selectedListType
        ) {
            Section(header: "Links") {
                NavigationLink(value: ListType.all) {
                    Label("All", systemImage: "tray.2")
                }
                NavigationLink(value: ListType.tags(selectedTag: nil)) {
                    Label("Tags", systemImage: "tray.2")
                }
                NavigationLink(value: ListType.downloaded) {
                    Label("Offline", systemImage: "archivebox")
                }
            }
            Section(header: "Favorites") {
                ForEach(overallAppState.tagState.favoriteTags) { tag in
                    NavigationLink(value: ListType.tagScoped(tag)) {
                        Label(tag.name, systemImage: "tag")
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            Task {
                                overallAppState.tagState.removeFavorite(tag: tag)
                            }
                        } label: {
                            Label("Remove Favorite", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .listStyle(SidebarListStyle())
        #if os(iOS)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        overallAppState.navigationState.showsSettings = true
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }
                    .sheet(
                        isPresented: $overallAppState.navigationState.showsSettings,
                        content: {
                            SettingsView(
                                settingsState: overallAppState.settingsState
                            )
                        }
                    )
                }
            }
        #endif
            .onAppear {
                if overallAppState.settingsState.isLoggedOut {
                    overallAppState.navigationState.showsSettings = true
                }
                if !overallAppState.tagState.didLoad {
                    Task {
                        await overallAppState.tagState.load()
                    }
                }
            }
    }
}
