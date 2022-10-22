//
//  LinkdingModel.swift
//  Aarle
//
//  Created by Martin Hartl on 26.03.22.
//

import Foundation

public struct LinkdingResult: Codable {
    public let results: [LinkdingLink]
}

public struct LinkdingLink: Codable, Hashable {
    public init(
        id: Int,
        url: URL,
        title: String? = nil,
        description: String? = nil,
        websiteTitle: String? = nil,
        websiteDescription: String? = nil,
        tagNames: [String]? = nil,
        dateAdded: Date
    ) {
        self.id = id
        self.url = url
        self.title = title
        self.description = description
        self.websiteTitle = websiteTitle
        self.websiteDescription = websiteDescription
        self.tagNames = tagNames
        self.dateAdded = dateAdded
    }

    public let id: Int
    public let url: URL
    public let title: String?
    public let description: String?
    public let websiteTitle: String?
    public let websiteDescription: String?
    public let tagNames: [String]?
    public let dateAdded: Date
}

public extension Link {
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

public struct LinkdingPostLink: Codable {
    public init(url: URL, title: String? = nil, description: String? = nil, tagNames: [String]? = nil) {
        self.url = url
        self.title = title
        self.description = description
        self.tagNames = tagNames
    }

    public let url: URL
    public let title: String?
    public let description: String?
    public let tagNames: [String]?
}

public struct LinkdingTagResult: Codable {
    public init(results: [Tag]) {
        self.results = results
    }

    public let results: [Tag]
}
