//
//  PinboardLink.swift
//  Aarlo
//
//  Created by martinhartl on 29.01.22.
//

import Foundation

struct PinboardLink: Codable, Hashable {
    let href: String
    let description: String?
    let extended: String?

    let tags: String?
    let time: Date
    let shared: String
}

extension Link {
    static func fromPinboardLink(link: PinboardLink) -> Link {
        Link(
            id: link.href,
            url: URL(string: link.href)!,
            title: link.description,
            description: link.extended,
            tags: link.tags?.components(separatedBy: " ") ?? [],
            private: link.shared == "yes",
            created: link.time
        )
    }
}
