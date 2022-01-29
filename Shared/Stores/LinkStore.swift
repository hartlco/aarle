//
//  LinkStore.swift
//  Aarlo
//
//  Created by martinhartl on 05.01.22.
//

import Foundation
import Combine

final class LinkStore: ObservableObject {
    @Published var links: [Link]
    @Published var isLoading: Bool
    @Published var canLoadMore = false

    private let client: ShaarliClient
    private let tagScope: String?

    init(
        client: ShaarliClient,
        tagScope: String? = nil
    ) {
        self.client = client
        self.tagScope = tagScope
        self.links = []
        self.isLoading = false
    }

    private var scopedTages: [String] {
        let tags: [String]
        if let tagScope = tagScope {
            tags = [tagScope]
        } else {
            tags = []
        }

        return tags
    }

#if DEBUG
    static let mock = LinkStore(client: ShaarliClient(settingsStore: SettingsStore()))
#endif

    @MainActor func load() async throws {
        guard isLoading == false else { return }

        defer {
            isLoading = false
        }

        isLoading = true

        links = try await client.load(filteredByTags: scopedTages)

        canLoadMore = links.count == client.pageSize
    }

    @MainActor func loadMoreIfNeeded(link: Link) async throws {
        guard isLoading == false else { return }
        guard link.id == links.last?.id else { return }

        defer {
            isLoading = false
        }

        isLoading = true

        let links = try await client.loadMore(offset: links.count, filteredByTags: scopedTages)
        self.links.append(contentsOf: links)

        canLoadMore = links.count == client.pageSize
    }

    @MainActor func add(link: PostLink) async throws {
        guard isLoading == false else { return }
        isLoading = true

        try await client.createLink(link: link)

        isLoading = false
    }

    @MainActor func update(link: Link) async throws {
        guard isLoading == false else { return }
        isLoading = true

        try await client.updateLink(link: link)

        isLoading = false
    }

    @MainActor func delete(link: Link) async throws {
        guard isLoading == false else { return }
        isLoading = true

        try await client.deleteLink(link: link)

        isLoading = false
    }
}
