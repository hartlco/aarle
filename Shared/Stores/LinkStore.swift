//
//  LinkStore.swift
//  Aarlo
//
//  Created by martinhartl on 05.01.22.
//

import Foundation
import Combine
import SwiftUI

final class LinkStore: ObservableObject {
    enum Action {
        case load
        case loadMoreIfNeeded(Link)
        case changeSearchText(String)
        case search
    }

    struct State {
        var links: [Link] = []
        var isLoading = false
        var canLoadMore = false
        var searchText = ""
    }

    private let client: BookmarkClient
    private let tagScope: String?

    @Published private var state = State()

    init(
        client: BookmarkClient,
        tagScope: String? = nil
    ) {
        self.client = client
        self.tagScope = tagScope
    }

    @MainActor var searchText: Binding<String> {
        Binding { [weak self] in
            return self?.state.searchText ?? ""
        } set: { [weak self] searchText in
            guard let self = self else { return }
            self.reduce(.changeSearchText(searchText))
        }
    }

    @MainActor func reduce(_ action: Action) {
        switch action {
        case .load, .search:
            Task {
                do {
                    try await load()
                } catch {
                    // TODO: Error handling
                    print(error)
                }
            }
        case let .loadMoreIfNeeded(link):
            Task {
                do {
                    try await loadMoreIfNeeded(link: link)
                } catch {
                    // TODO: Error handling
                    print(error)
                }
            }
        case let .changeSearchText(string):
            state.searchText = string

            if string.isEmpty {
                reduce(.load)
            }
        }
    }

    var links: [Link] {
        state.links
    }

    var canLoadMore: Bool {
        state.canLoadMore
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
    static let mock = LinkStore(client: MockClient())
#endif

    @MainActor private func load() async throws {
        guard state.isLoading == false else { return }

        defer {
            state.isLoading = false
        }

        state.isLoading = true

        state.links = try await client.load(filteredByTags: scopedTages, searchTerm: state.searchText)

        state.canLoadMore = state.links.count == client.pageSize
    }

    @MainActor private func loadMoreIfNeeded(link: Link) async throws {
        guard state.isLoading == false else { return }
        guard link.id == state.links.last?.id else { return }

        defer {
            state.isLoading = false
        }

        state.isLoading = true

        let links = try await client.loadMore(offset: state.links.count, filteredByTags: scopedTages, searchTerm: state.searchText)
        self.state.links.append(contentsOf: links)

        state.canLoadMore = links.count == client.pageSize
    }

    @MainActor func add(link: PostLink) async throws {
        guard state.isLoading == false else { return }
        state.isLoading = true

        try await client.createLink(link: link)

        state.isLoading = false
    }

    @MainActor func update(link: Link) async throws {
        guard state.isLoading == false else { return }
        state.isLoading = true

        try await client.updateLink(link: link)

        state.isLoading = false
    }

    @MainActor func delete(link: Link) async throws {
        guard state.isLoading == false else { return }
        state.isLoading = true

        try await client.deleteLink(link: link)

        state.isLoading = false
    }
}
