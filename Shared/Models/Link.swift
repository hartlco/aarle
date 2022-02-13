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
        self.wrappedValue = String(intValue)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}

struct Link: Codable, Identifiable, Hashable, Sendable {
    @IntRepresentedString var id: String
    let url: URL
    let title: String?
    let description: String?
    var tags: [String]
    let `private`: Bool

    // TODO: Handle Date

    let created: Date
//    let updated: Date

    #if DEBUG
    static let mock = Link(
        id: "1",
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

extension URL: Sendable { }
extension Date: Sendable { }
