//
//  LinkItemView.swift
//  Aarlo
//
//  Created by martinhartl on 02.01.22.
//

import SwiftUI

struct LinkItemView: View {
    let link: Link

    let columns = [
        GridItem(.adaptive(minimum: 20, maximum: 200))
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 2.0) {
            if let title = link.title {
                Text(title)
                    .font(.title3)
                    .bold()
            }
            Text(link.url.host ?? link.url.absoluteString)
                .foregroundColor(.tint)
            if let description = link.description, !description.isEmpty {
                Text(description)
                    .font(.body)
            }
            if !tagsString.isEmpty {
                Text(tagsString)
                    .font(.footnote)
                    .foregroundColor(.secondaryLabel)
                    .padding(2.0)
            }
        }
        .padding(4.0)
    }

    private var tagsString: String {
        return link.tags.joined(separator: " • ")
    }
}

struct LinkItemView_Previews: PreviewProvider {
    static var previews: some View {
        let link = Link(
            id: 1,
            url: .init(string: "https://hartl.co")!,
            title: "Title",
            description: "Description with a few more words than just the title",
            tags: ["swift", "macos"],
            private: false,
            created: Date.now
        )
        LinkItemView(link: link)
    }
}
