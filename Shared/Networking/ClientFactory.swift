//
//  ClientFactory.swift
//  Aarlo
//
//  Created by martinhartl on 29.01.22.
//

import KeychainAccess
import Foundation

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

    func load(filteredByTags tags: [String], searchTerm: String?) async throws -> [Link] {
        return []
    }

    func loadMore(offset: Int, filteredByTags tags: [String], searchTerm: String?) async throws -> [Link] {
        []
    }

    func createLink(link: PostLink) async throws {
    }

    func updateLink(link: Link) async throws {
    }

    func deleteLink(link: Link) async throws {
    }

    func loadTags() async throws -> [Tag] {
        []
    }
}
#endif

final class UniversalClient: BookmarkClient {
    private let shaarliClient: ShaarliClient
    private let pinboardClient: PinboardClient

    init(keychain: Keychain) {
        self.keychain = keychain
        self.shaarliClient = ShaarliClient(keychain: keychain)
        self.pinboardClient = PinboardClient(keychain: keychain)
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

    private let keychain: Keychain
    private var client: BookmarkClient {
        switch keychain.accountType {
        case .shaarli:
            return shaarliClient
        case .pinboard:
            return pinboardClient
        }
    }
}
