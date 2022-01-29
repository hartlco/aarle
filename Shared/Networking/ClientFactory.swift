//
//  ClientFactory.swift
//  Aarlo
//
//  Created by martinhartl on 29.01.22.
//

import Foundation

protocol BookmarkClient {
    var pageSize: Int { get }

    func load(filteredByTags tags: [String]) async throws -> [Link]
    func loadMore(offset: Int, filteredByTags tags: [String]) async throws -> [Link]
    func createLink(link: PostLink) async throws
    func updateLink(link: Link) async throws
    func deleteLink(link: Link) async throws
    func loadTags() async throws -> [Tag]
}

#if DEBUG
final class MockClient: BookmarkClient {
    let pageSize = 20

    func load(filteredByTags tags: [String]) async throws -> [Link] {
        return []
    }

    func loadMore(offset: Int, filteredByTags tags: [String]) async throws -> [Link] {
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
    private let pinboardClient: ShaarliClient

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
        self.shaarliClient = ShaarliClient(settingsStore: settingsStore, test: true)
        self.pinboardClient = ShaarliClient(settingsStore: settingsStore, test: true)
    }

    var pageSize: Int {
        client.pageSize
    }

    func load(filteredByTags tags: [String]) async throws -> [Link] {
        try await client.load(filteredByTags: tags)
    }

    func loadMore(offset: Int, filteredByTags tags: [String]) async throws -> [Link] {
        try await client.loadMore(offset: offset, filteredByTags: tags)
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

    private let settingsStore: SettingsStore
    private var client: BookmarkClient {
        switch settingsStore.accountType.wrappedValue {
        case .shaarli:
            return shaarliClient
        case .pinboard:
            return pinboardClient
        }
    }
}
