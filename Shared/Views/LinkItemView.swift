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
            if let description = link.description {
                Text(description)
                    .font(.body)
            }
            LazyHGrid(rows: columns, spacing: 20) {
                ForEach(link.tags, id: \.self) { item in
                    Text(item)
                        .padding(EdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4))
                        .background(.tint)
                        .cornerRadius(4.0)
                }
            }
        }
        .padding(4.0)
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
