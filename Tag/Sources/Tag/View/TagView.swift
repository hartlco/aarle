//
//  TagView.swift
//  Aarlo
//
//  Created by martinhartl on 15.01.22.
//

import SwiftUI
import Types

public struct TagView: View {
    let tag: Tag
    let isFavorite: Bool
    let favorite: () -> Void

    public init(tag: Tag, isFavorite: Bool, favorite: @escaping () -> Void) {
        self.tag = tag
        self.isFavorite = isFavorite
        self.favorite = favorite
    }

    public var body: some View {
        HStack {
            Text(tag.name)
                .font(.headline)
            if let occurrences = tag.occurrences {
                Text(String("• \(occurrences)"))
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            Spacer()
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
            TagView(tag: Tag(name: "Test", occurrences: 12), isFavorite: true) {}
            TagView(tag: Tag(name: "Test", occurrences: 12), isFavorite: false) {}
        }
    }
#endif
