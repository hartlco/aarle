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
    @EnvironmentObject var appStore: AppStore

    var body: some View {
        List(selection: appStore.selectedListType) {
            Section(header: "Links") {
                NavigationLink(
                    destination: ContentView(
                        title: "Links",
                        listType: .all
                    ),
                    tag: ListType.all,
                    selection: appStore.selectedListType
                ) {
                    Label("All", systemImage: "tray.2")
                }
                NavigationLink(
                    destination: TagListView(),
                    tag: ListType.tags,
                    selection: appStore.selectedListType
                ) {
                    Label("Tags", systemImage: "tag")
                }
            }
            Section(header: "Favorites") {
                ForEach(tagStore.favoriteTags) { tag in
                    NavigationLink(
                        destination: ContentView(
                            title: tag.name,
                            listType: .tagScoped(tag)
                        ),
                        tag: ListType.tagScoped(tag),
                        selection: appStore.selectedListType
                    ) {
                        Label(tag.name, systemImage: "tag")
                    }.contextMenu {
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
                appStore.reduce(.showSettings)
            }
        }
        .equatable(by: equation)
    }

    private var equation: SidebarEquatable {
        SidebarEquatable(
            favoriteTags: tagStore.favoriteTags,
            showsSettings: appStore.showsSettings.wrappedValue,
            listSelection: appStore.selectedListType.wrappedValue
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
