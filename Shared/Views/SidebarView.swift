//
//  SidebarView.swift
//  Aarlo
//
//  Created by martinhartl on 07.01.22.
//

import SwiftUI
import SwiftUIX

struct SidebarView: View {
    struct SidebarEquatable: Equatable {
        var favoriteTags: [Tag]
        var showsSettings: Bool
        var listSelection: ListType?
    }

    @EnvironmentObject var linkStore: LinkStore
    @EnvironmentObject var tagViewStore: TagViewStore
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var appViewStore: AppViewStore

    var body: some View {
        List(selection: appViewStore.binding(get: \.selectedListType, send: { .setSelectedListType($0) })) {
            Section(header: "Links") {
                NavigationLink(
                    destination: ContentView(
                        title: "Links",
                        listType: .all
                    )
                ) {
                    Label("All", systemImage: "tray.2")
                }
                .tag(ListType.all)
                NavigationLink(
                    destination: TagListView()
                ) {
                    Label("Tags", systemImage: "tag")
                }
                .tag(ListType.tags)
            }
            Section(header: "Favorites") {
                ForEach(tagViewStore.favoriteTags) { tag in
                    NavigationLink(
                        destination: ContentView(
                            title: tag.name,
                            listType: .tagScoped(tag)
                        )
                    ) {
                        Label(tag.name, systemImage: "tag")
                    }
                    .tag(ListType.tagScoped(tag))
                    .contextMenu {
                        Button(role: .destructive) {
                            Task {
                                tagViewStore.send(.removeFavorite(tag))
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
                    appViewStore.send(.showSettings)
                } label: {
                    Label("Settings", systemImage: "gear")
                }
                .sheet(
                    isPresented: appViewStore.binding(get: \.showsSettings, send: { .setShowSettings($0) }),
                    content: {
                        SettingsView()
                    }
                )
            }
        }
#endif
        .onAppear {
            if settingsStore.isLoggedOut {
                appViewStore.send(.showSettings)
            }
        }
        .equatable(by: equation)
    }

    private var equation: SidebarEquatable {
        SidebarEquatable(
            favoriteTags: tagViewStore.favoriteTags,
            showsSettings: appViewStore.showsSettings,
            listSelection: appViewStore.selectedListType
        )
    }
}

#if DEBUG
struct SidebarView_Previews: PreviewProvider {
    static var previews: some View {
        SidebarView().environmentObject(TagViewStore.mock).environmentObject(LinkStore.mock)
    }
}
#endif
