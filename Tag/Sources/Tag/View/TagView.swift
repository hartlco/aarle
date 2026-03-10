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
        HStack(spacing: 12) {
            Image(systemName: "number")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            VStack(alignment: .leading, spacing: 2) {
                Text(tag.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                if let occurrences = tag.occurrences {
                    Text("\(occurrences) bookmark\(occurrences == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button {
                favorite()
            } label: {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .font(.caption)
                    .foregroundStyle(isFavorite ? .yellow : .secondary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 4)
    }
}

#if DEBUG
    struct TagView_Previews: PreviewProvider {
        static var previews: some View {
            List {
                TagView(tag: Tag(name: "swift", occurrences: 12), isFavorite: true) {}
                TagView(tag: Tag(name: "ios-development", occurrences: 1), isFavorite: false) {}
                TagView(tag: Tag(name: "rust", occurrences: 5), isFavorite: false) {}
            }
        }
    }
#endif
