//
//  TagListView.swift
//  Aarlo
//
//  Created by martinhartl on 14.01.22.
//

import SwiftUI

struct TagListView: View {
    let linkStore: LinkStore

    var body: some View {
        List(linkStore.tags) { tag in
            Text(tag.name)
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
