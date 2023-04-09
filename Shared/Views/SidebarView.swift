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
    @ObservedObject var navigationState: NavigationState
    @ObservedObject var tagState: TagState
    @ObservedObject var settingsState: SettingsState

    var body: some View {
        List(
            selection: $navigationState.selectedListType
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
                ForEach(tagState.favoriteTags) { tag in
                    NavigationLink(value: ListType.tagScoped(tag)) {
                        Label(tag.name, systemImage: "tag")
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            Task {
                                tagState.removeFavorite(tag: tag)
                            }
                        } label: {
                            Label("Remove Favorite", systemImage: "trash")
                        }
                    }
                }
            }
//            Section(header: "All Tags") {
//                ForEach(tagState.tags) { tag in
//                    NavigationLink(value: ListType.tagScoped(tag)) {
//                        TagView(
//                            tag: tag,
//                            isFavorite: tagState.favoriteTags.contains(tag)
//                        ) {
//                            if tagState.favoriteTags.contains(tag) {
//                                tagState.removeFavorite(tag: tag)
//                            } else {
//                                tagState.addFavorite(tag: tag)
//                            }
//                        }
//                    }
//                }
//            }
        }
        .listStyle(SidebarListStyle())
        #if os(iOS)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        navigationState.showsSettings = true
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }
                    .sheet(
                        isPresented: $navigationState.showsSettings,
                        content: {
                            SettingsView(
                                settingsState: settingsState
                            )
                        }
                    )
                }
            }
        #endif
            .onAppear {
                if settingsState.isLoggedOut {
                    navigationState.showsSettings = true
                }
                if !tagState.didLoad {
                    Task {
                        await tagState.load()
                    }
                }
            }
    }
}
