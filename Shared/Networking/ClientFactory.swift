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
    private let linkdingClient: LinkdingClient

    init(keychain: AarleKeychain) {
        self.keychain = keychain
        linkdingClient = LinkdingClient(keychain: keychain)
    }

    var pageSize: Int {
        linkdingClient.pageSize
    }

    func load(filteredByTags tags: [String], searchTerm: String?) async throws -> [Link] {
        try await linkdingClient.load(filteredByTags: tags, searchTerm: searchTerm)
    }

    func loadMore(offset: Int, filteredByTags tags: [String], searchTerm: String?) async throws -> [Link] {
        try await linkdingClient.loadMore(offset: offset, filteredByTags: tags, searchTerm: searchTerm)
    }

    func createLink(link: PostLink) async throws {
        try await linkdingClient.createLink(link: link)
    }

    func updateLink(link: Link) async throws {
        try await linkdingClient.updateLink(link: link)
    }

    func deleteLink(link: Link) async throws {
        try await linkdingClient.deleteLink(link: link)
    }

    func loadTags() async throws -> [Tag] {
        try await linkdingClient.loadTags()
    }

    func loadUnread() async throws -> [Link] {
        try await linkdingClient.loadUnread()
    }

    func markAsRead(linkId: String) async throws {
        try await linkdingClient.markAsRead(linkId: linkId)
    }

    func markAsUnread(linkId: String) async throws {
        try await linkdingClient.markAsUnread(linkId: linkId)
    }

    private let keychain: AarleKeychain
}
