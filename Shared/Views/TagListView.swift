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
    @State var selectedLink: Link?

    var body: some View {
        List(tagStore.tags) { tag in
            NavigationLink {
                #if os(macOS)
                // TODO: Handle selection App wide
                NavigationView {
                    ContentView(
                        title: "Links",
                        linkStore: LinkStore(
                            client: ShaarliClient(),
                            tagScope: tag.name
                        ),
                        tagStore: tagStore,
                        linkSelection: $selectedLink
                    )
                    WebView(data: webViewData)
                }
                #else
                ContentView(
                    title: "Links",
                    linkStore: LinkStore(
                        client: ShaarliClient(),
                        tagScope: tag.name
                    ),
                    tagStore: tagStore,
                    linkSelection: $selectedLink
                )
                #endif
            } label: {
                TagView(
                    tag: tag,
                    isFavorite: tagStore.favoriteTags.contains(tag)
                ) {
                    if tagStore.favoriteTags.contains(tag) {
                        tagStore.remove(favoriteTag: tag)
                    } else {
                        tagStore.add(favoriteTag: tag)
                    }
                }
            }
        }
        .task {
            do {
                try await tagStore.loadTags()
            } catch let error {
                print(error)
            }
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
