//
//  TagView.swift
//  Aarlo
//
//  Created by martinhartl on 15.01.22.
//

import SwiftUI

struct TagView: View {
    let tag: Tag
    var body: some View {
        HStack {
            Text(tag.name)
                .font(.headline)
            Text(String(tag.occurrences))
                .font(.caption)
                .padding(4.0)
                .background(.faintTint)
                .cornerRadius(6.0)
        }
        .padding(2.0)
    }
}

#if DEBUG
struct TagView_Previews: PreviewProvider {
    static var previews: some View {
        TagView(tag: Tag(name: "Test", occurrences: 12))
    }
}
#endif
