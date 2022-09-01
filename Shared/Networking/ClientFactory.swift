//
//  ClientFactory.swift
//  Aarlo
//
//  Created by martinhartl on 29.01.22.
//

import Foundation
import Types

enum ClientError: Error {
    case unknownURL
}

protocol BookmarkClient {
    var pageSize: Int { get }

    func load(filteredByTags tags: [String], searchTerm: String?) async throws -> [Link]
    func loadMore(offset: Int, filteredByTags tags: [String], searchTerm: String?) async throws -> [Link]
    func createLink(link: PostLink) async throws
    func updateLink(link: Link) async throws
    func deleteLink(link: Link) async throws
    func loadTags() async throws -> [Tag]
}

#if DEBUG
    final class MockClient: BookmarkClient {
        let pageSize = 20

        func load(filteredByTags _: [String], searchTerm _: String?) async throws -> [Link] {
            return []
        }

        func loadMore(offset _: Int, filteredByTags _: [String], searchTerm _: String?) async throws -> [Link] {
            []
        }

        func createLink(link _: PostLink) async throws {}

        func updateLink(link _: Link) async throws {}

        func deleteLink(link _: Link) async throws {}

        func loadTags() async throws -> [Tag] {
            []
        }
    }
#endif

final class UniversalClient: BookmarkClient {
    private let shaarliClient: ShaarliClient
    private let pinboardClient: PinboardClient
    private let linkdingClient: LinkdingClient

    init(keychain: AarleKeychain) {
        self.keychain = keychain
        shaarliClient = ShaarliClient(keychain: keychain)
        pinboardClient = PinboardClient(keychain: keychain)
        linkdingClient = LinkdingClient(keychain: keychain)
    }

    var pageSize: Int {
        client.pageSize
    }

    func load(filteredByTags tags: [String], searchTerm: String?) async throws -> [Link] {
        try await client.load(filteredByTags: tags, searchTerm: searchTerm)
    }

    func loadMore(offset: Int, filteredByTags tags: [String], searchTerm: String?) async throws -> [Link] {
        try await client.loadMore(offset: offset, filteredByTags: tags, searchTerm: searchTerm)
    }

    func createLink(link: PostLink) async throws {
        try await client.createLink(link: link)
    }

    func updateLink(link: Link) async throws {
        try await client.updateLink(link: link)
    }

    func deleteLink(link: Link) async throws {
        try await client.deleteLink(link: link)
    }

    func loadTags() async throws -> [Tag] {
        try await client.loadTags()
    }

    private let keychain: AarleKeychain
    private var client: BookmarkClient {
        switch keychain.accountType {
        case .shaarli:
            return shaarliClient
        case .pinboard:
            return pinboardClient
        case .linkding:
            return linkdingClient
        }
    }
}
