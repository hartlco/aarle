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

    private var tags: [String] {
        let tags: [String]
        if let tagScope = tagScope {
            tags = [tagScope]
        } else {
            tags = []
        }

        return tags
    }

#if DEBUG
    static let mock = LinkStore(client: ShaarliClient())
#endif

    @MainActor func load() async throws {
        guard isLoading == false else { return }
        isLoading = true

        links = try await client.load(filteredByTags: tags)

        isLoading = false
    }

    @MainActor func loadMoreIfNeeded(link: Link) async throws {
        guard isLoading == false else { return }
        guard link.id == links.last?.id else { return }

        isLoading = true

        let links = try await client.loadMore(offset: links.count, filteredByTags: tags)
        self.links.append(contentsOf: links)

        isLoading = false
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
