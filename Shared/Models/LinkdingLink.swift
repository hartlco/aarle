//
//  LinkdingModel.swift
//  Aarle
//
//  Created by Martin Hartl on 26.03.22.
//

import Foundation
import Types

struct LinkdingResult: Codable {
    let results: [LinkdingLink]
}

struct LinkdingLink: Codable, Hashable {
    let id: Int
    let url: URL
    let title: String?
    let description: String?

    let websiteTitle: String?
    let websiteDescription: String?

    let tagNames: [String]?
    let dateAdded: Date
}

extension Link {
    static func fromLinkdingLink(link: LinkdingLink) -> Link {
        let titleFallback: String?
        if let title = link.title, !title.isEmpty {
            titleFallback = title
        } else {
            titleFallback = link.websiteTitle
        }

        let descriptionFallback: String?
        if let description = link.description, !description.isEmpty {
            descriptionFallback = description
        } else {
            descriptionFallback = link.websiteDescription
        }

        return Link(
            id: String(link.id),
            url: link.url,
            title: titleFallback,
            description: descriptionFallback,
            tags: link.tagNames ?? [],
            private: true,
            created: link.dateAdded
        )
    }
}

struct LinkdingPostLink: Codable {
    let url: URL
    let title: String?
    let description: String?
    let tagNames: [String]?
}

struct LinkdingTagResult: Codable {
    let results: [Tag]
}
