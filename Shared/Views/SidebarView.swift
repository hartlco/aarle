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
    @EnvironmentObject var tagStore: TagStore
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
                ForEach(tagStore.favoriteTags) { tag in
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
                                tagStore.reduce(.removeFavorite(tag))
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
                    appStore.reduce(.showSettings)
                } label: {
                    Label("Settings", systemImage: "gear")
                }
                .sheet(
                    isPresented: appStore.showsSettings,
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
            favoriteTags: tagStore.favoriteTags,
            showsSettings: appViewStore.showsSettings,
            listSelection: appViewStore.selectedListType
        )
    }
}

#if DEBUG
struct SidebarView_Previews: PreviewProvider {
    static var previews: some View {
        SidebarView().environmentObject(TagStore.mock).environmentObject(LinkStore.mock)
    }
}
#endif
