//
//  Link.swift
//  Aarlo
//
//  Created by martinhartl on 02.01.22.
//

import Foundation

@propertyWrapper
public struct IntRepresentedString: Codable, Equatable, Hashable, Sendable {
    public var wrappedValue: String

    public init(wrappedValue: String) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let intValue = try container.decode(Int.self)
        wrappedValue = String(intValue)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}

public struct Link: Codable, Identifiable, Hashable, Sendable {
    public init(
        id: String,
        url: URL,
        title: String? = nil,
        description: String? = nil,
        tags: [String],
        `private`: Bool,
        created: Date,
        previewImageUrl: URL? = nil,
        unread: Bool = false
    ) {
        self.id = id
        self.url = url
        self.title = title
        self.description = description
        self.tags = tags
        self.`private` = `private`
        self.created = created
        self.previewImageUrl = previewImageUrl
        self.unread = unread
    }

    @IntRepresentedString public var id: String
    public let url: URL
    public let title: String?
    public let description: String?
    public var tags: [String]
    public let `private`: Bool

    // TODO: Handle Date

    public let created: Date
    public let previewImageUrl: URL?
    public let unread: Bool
//    let updated: Date

#if DEBUG
    public static let mock = Link(
        id: "1",
        url: .init(string: "https://hartl.co")!,
        title: "Title",
        description: "Description with a few more words than just the title",
        tags: ["swift", "macos"],
        private: false,
        created: Date.now,
        previewImageUrl: nil,
        unread: false
    )
#endif
}

public struct PostLink: Codable {
    public init(
        url: URL,
        title: String? = nil,
        description: String? = nil,
        tags: [String],
        `private`: Bool,
        created: Date,
        unread: Bool = false
    ) {
        self.url = url
        self.title = title
        self.description = description
        self.tags = tags
        self.`private` = `private`
        self.created = created
        self.unread = unread
    }

    public let url: URL
    public let title: String?
    public let description: String?
    public let tags: [String]
    public let `private`: Bool
    public let created: Date
    public let unread: Bool
//    let updated: Date
}

public extension PostLink {
    init(link: Link) {
        url = link.url
        title = link.title
        description = link.description
        tags = link.tags
        self.private = link.private
        created = link.created
//        self.updated = link.updated
    }
}
