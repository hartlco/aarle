//
//  Link.swift
//  Aarlo
//
//  Created by martinhartl on 02.01.22.
//

import Foundation

struct Link: Codable, Identifiable, Hashable {
    let id: Int
    let url: URL
    let title: String?
    let description: String?
    let tags: [String]
    let `private`: Bool

    // TODO: Handle Date

    let created: Date
//    let updated: Date

    #if DEBUG
    static let mock = Link(
        id: 1,
        url: .init(string: "https://hartl.co")!,
        title: "Title",
        description: "Description with a few more words than just the title",
        tags: ["swift", "macos"],
        private: false,
        created: Date.now
    )
    #endif
}

struct PostLink: Codable {
    let url: URL
    let title: String?
    let description: String?
    let tags: [String]
    let `private`: Bool
    let created: Date
//    let updated: Date
}

extension PostLink {
    init(link: Link) {
        self.url = link.url
        self.title = link.title
        self.description = link.description
        self.tags = link.tags
        self.private = link.private
        self.created = link.created
//        self.updated = link.updated
    }
}
