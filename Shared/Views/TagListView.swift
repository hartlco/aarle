//
//  TagListView.swift
//  Aarlo
//
//  Created by martinhartl on 14.01.22.
//

import SwiftUI

// TODO: Add tag renaming
struct TagListView: View {
    @ObservedObject var linkStore: LinkStore

    let webViewData = WebViewData(url: nil)
    @State var selectedLink: Link?

    var body: some View {
        List(linkStore.tags) { tag in
            NavigationLink {
                #if os(macOS)
                // TODO: Handle selection App wide
                NavigationView {
                    ContentView(
                        title: "Links",
                        linkStore: LinkStore(client: ShaarliClient(), tagScope: tag.name),
                        linkSelection: $selectedLink
                    )
                    WebView(data: webViewData)
                }
                #else
                ContentView(
                    title: "Links",
                    linkStore: LinkStore(client: ShaarliClient(), tagScope: tag.name),
                    linkSelection: $selectedLink
                )
                #endif
            } label: {
                TagView(tag: tag)
            }
        }
        .task {
            do {
                try await linkStore.loadTags()
            } catch let error {
                print(error)
            }
        }
    }
}

#if DEBUG
struct TagListView_Previews: PreviewProvider {
    static var previews: some View {
        TagListView(linkStore: .mock)
    }
}
#endif
