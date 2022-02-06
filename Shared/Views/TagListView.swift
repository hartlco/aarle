//
//  TagListView.swift
//  Aarlo
//
//  Created by martinhartl on 14.01.22.
//

import SwiftUI

// TODO: Add tag renaming
struct TagListView: View {
    let webViewData = WebViewData(url: nil)

    @EnvironmentObject var tagStore: TagStore
    @EnvironmentObject var appStore: AppStore
    @EnvironmentObject var settingsStore: SettingsStore

    private var navigationBarItemPlacement: ToolbarItemPlacement {
        #if os(macOS)
        return .automatic
        #else
        return .navigationBarTrailing
        #endif
    }

    var body: some View {
        if tagStore.isLoading {
            ProgressView()
                .padding()
        }
        listView
    }

    var listView: some View {
        List(tagStore.tags) { tag in
            NavigationLink {
                #if os(macOS)
                NavigationView {
                    ContentView(
                        title: "Links",
                        listType: .tagScoped(tag)
                    )
                    WebView(data: webViewData)
                }
                #else
                ContentView(
                    title: "Links",
                    listType: .tagScoped(tag)
                )
                #endif
            } label: {
                TagView(
                    tag: tag,
                    isFavorite: tagStore.favoriteTags.contains(tag)
                ) {
                    if tagStore.favoriteTags.contains(tag) {
                        tagStore.reduce(.removeFavorite(tag))
                    } else {
                        tagStore.reduce(.addFavorite(tag))
                    }
                }
            }
        }
        .navigationTitle("Tags")
        .toolbar {
            // TODO: Dont show double plus
            ToolbarItem {
                Button {
                    appStore.reduce(.showAddView)
                } label: {
                    Label("Add", systemImage: "plus")
                }
#if os(iOS)
                .sheet(
                    isPresented: appStore.showsAddView,
                    onDismiss: nil,
                    content: {
                        LinkAddView()
                    }
                )
#endif
            }
        }
        .task {
            if !tagStore.didLoad {
                tagStore.reduce(.load)
            }
        }
    }
}

#if DEBUG
struct TagListView_Previews: PreviewProvider {
    static var previews: some View {
        TagListView().environmentObject(TagStore.mock)
    }
}
#endif
