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

    @EnvironmentObject var tagViewStore: TagViewStore
    @EnvironmentObject var appViewStore: AppViewStore
    @EnvironmentObject var settingsViewStore: SettingsViewStore

    private var navigationBarItemPlacement: ToolbarItemPlacement {
        #if os(macOS)
        return .automatic
        #else
        return .navigationBarTrailing
        #endif
    }

    var body: some View {
        if tagViewStore.isLoading {
            ProgressView()
                .padding()
        }
        listView
    }

    var listView: some View {
        List(tagViewStore.tags) { tag in
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
                    isFavorite: tagViewStore.favoriteTags.contains(tag)
                ) {
                    if tagViewStore.favoriteTags.contains(tag) {
                        tagViewStore.send(.removeFavorite(tag))
                    } else {
                        tagViewStore.send(.addFavorite(tag))
                    }
                }
            }
        }
        .navigationTitle("Tags")
        .toolbar {
            // TODO: Dont show double plus
            ToolbarItem {
                Button {
                    appViewStore.send(.showAddView)
                } label: {
                    Label("Add", systemImage: "plus")
                }
#if os(iOS)
                .sheet(
                    isPresented: appViewStore.binding(get: \.showsAddView, send: { .setShowAddView($0) }),
                    onDismiss: nil,
                    content: {
                        LinkAddView()
                    }
                )
#endif
            }
        }
        .task {
            if !tagViewStore.didLoad {
                tagViewStore.send(.load)
            }
        }
    }
}

#if DEBUG
struct TagListView_Previews: PreviewProvider {
    static var previews: some View {
        TagListView().environmentObject(TagViewStore.mock)
    }
}
#endif
