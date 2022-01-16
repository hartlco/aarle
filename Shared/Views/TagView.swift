//
//  TagView.swift
//  Aarlo
//
//  Created by martinhartl on 15.01.22.
//

import SwiftUI

struct TagView: View {
    let tag: Tag
    let isFavorite: Bool
    let favorite: () -> Void

    var body: some View {
        HStack {
            Text(tag.name)
                .font(.headline)
            Spacer()
            Text(String(tag.occurrences))
                .font(.caption)
                .padding(4.0)
                .background(.faintTint)
                .cornerRadius(6.0)
            Button {
                favorite()
            } label: {
                Label(
                    isFavorite ? "Unfavorite" : "Favorite",
                    systemImage: isFavorite ? "star.fill" : "star"
                ).labelStyle(.iconOnly)
            }
            .buttonStyle(PlainButtonStyle()) 

        }
        .padding(2.0)
    }
}

#if DEBUG
struct TagView_Previews: PreviewProvider {
    static var previews: some View {
        TagView(tag: Tag(name: "Test", occurrences: 12), isFavorite: true) {

        }
        TagView(tag: Tag(name: "Test", occurrences: 12), isFavorite: false) {

        }
    }
}
#endif
