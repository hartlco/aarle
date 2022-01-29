//
//  TagListView.swift
//  Aarlo
//
//  Created by martinhartl on 14.01.22.
//

import SwiftUI

// TODO: Add tag renaming
struct TagListView: View {
    @ObservedObject var tagStore: TagStore

    let webViewData = WebViewData(url: nil)

    @EnvironmentObject var settingsStore: SettingsStore

    private var navigationBarItemPlacement: ToolbarItemPlacement {
        #if os(macOS)
        return .automatic
        #else
        return .navigationBarTrailing
        #endif
    }

    var body: some View {
        List(tagStore.tags) { tag in
            NavigationLink {
                #if os(macOS)
                // TODO: Handle selection App wide
                NavigationView {
                    ContentView(
                        title: "Links",
                        linkStore: LinkStore(
                            client: UniversalClient(settingsStore: settingsStore),
                            tagScope: tag.name
                        )
                    )
                    WebView(data: webViewData)
                }
                #else
                ContentView(
                    title: "Links",
                    linkStore: LinkStore(
                        client: ShaarliClient(),
                        tagScope: tag.name
                    )
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
            ToolbarItem(placement: navigationBarItemPlacement) {
                Button("Load") {
                    Task {
                        tagStore.reduce(.load)
                    }
                }
            }
        }
        .task {
            tagStore.reduce(.load)
        }
    }
}

#if DEBUG
struct TagListView_Previews: PreviewProvider {
    static var previews: some View {
        TagListView(tagStore: .mock)
    }
}
#endif
