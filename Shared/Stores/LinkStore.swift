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

    init(
        client: ShaarliClient
    ) {
        self.client = client
        self.links = []
        self.isLoading = false
    }

#if DEBUG
    static let mock = LinkStore(client: ShaarliClient())
#endif

    @MainActor func load() async throws {
        guard isLoading == false else { return }
        isLoading = true

        links = try await client.load()

        isLoading = false
    }

    @MainActor func loadMoreIfNeeded(link: Link) async throws {
//        guard isLoading == false else { return }
//        guard link.id == links.last?.id else { return }
//
//        isLoading = true
//
//        let links = try await client.loadMore(offset: links.count)
//        self.links.append(contentsOf: links)
//
//        isLoading = false
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
}
