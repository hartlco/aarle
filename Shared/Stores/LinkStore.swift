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
        case loadAll
        case load(ListType)
        case loadMoreIfNeeded(ListType, Link)
        case changeSearchText(String)
        case search(ListType)
    }

    struct State {
        // TODO: Move into subStore
        struct ListState {
            var links: [Link] = []
            var tagScope: String?
            var canLoadMore = false
        }

        var searchText = ""
        var isLoading = false
        var listStates: [ListType: ListState] = [:]
    }

    enum ListType: Hashable {
        case all
        case tagScoped(Tag)
    }

    private let client: BookmarkClient

    @Published private var state: State

    init(
        client: BookmarkClient,
        tagScope: String? = nil
    ) {
        self._state = Published(initialValue: State())
        self.client = client
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
        case .loadAll:
            // TODO: Add
            break
        case let .search(type):
            Task {
                do {
                    try await load(type: type)
                } catch {
                    // TODO: Error handling
                    print(error)
                }
            }
        case let .load(type):
            Task {
                do {
                    try await load(type: type)
                } catch {
                    // TODO: Error handling
                    print(error)
                }
            }
        case let .loadMoreIfNeeded(type, link):
            Task {
                do {
                    try await loadMoreIfNeeded(type: type, link: link)
                } catch {
                    // TODO: Error handling
                    print(error)
                }
            }
        case let .changeSearchText(string):
            state.searchText = string
        }
    }

    func links(for listType: ListType) -> [Link] {
        state.listStates[listType]?.links ?? []
    }

    func canLoadMore(for listType: ListType) -> Bool {
        state.listStates[listType]?.canLoadMore ?? false
    }

    private func scopedTages(for type: ListType) -> [String] {
        switch type {
        case .all:
            return []
        case .tagScoped(let tag):
            return [tag.name]
        }
    }

#if DEBUG
    static let mock = LinkStore(client: MockClient())
#endif

    @MainActor private func load(type: ListType) async throws {
        guard state.isLoading == false else { return }

        defer {
            state.isLoading = false
        }

        var listState = state.listStates[type] ?? State.ListState()

        state.isLoading = true

        listState.links = try await client.load(
            filteredByTags: scopedTages(for: type), 
            searchTerm: state.searchText
        )

        listState.canLoadMore = listState.links.count == client.pageSize
        state.listStates[type] = listState
    }

    @MainActor private func loadMoreIfNeeded(type: ListType, link: Link) async throws {
        guard state.isLoading == false else { return }

        var listState = state.listStates[type] ?? State.ListState()

        guard link.id == listState.links.last?.id else { return }

        defer {
            state.isLoading = false
        }

        state.isLoading = true

        let links = try await client.loadMore(
            offset: listState.links.count,
            filteredByTags: scopedTages(for: type), searchTerm: state.searchText
        )
        listState.links.append(contentsOf: links)

        listState.canLoadMore = links.count == client.pageSize
        state.listStates[type] = listState
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
