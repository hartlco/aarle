//
//  LinkStore.swift
//  Aarlo
//
//  Created by martinhartl on 05.01.22.
//

import Foundation
import Combine
import SwiftUI

enum ListType: Hashable, Equatable, Sendable {
    case all
    case tags
    case tagScoped(Tag)
}

final class LinkStore: ObservableObject {
    enum Action: Sendable {
        case load(ListType)
        case loadMoreIfNeeded(ListType, Link)
        case changeSearchText(String, listType: ListType)
        case search(ListType)
        case setShowLoadingError(Bool)
        case delete(ListType, Link)
    }

    struct State {
        // TODO: Move into subStore
        struct ListState {
            var links: [Link] = []
            var tagScope: String?
            var canLoadMore = false
            var searchText = ""
            var didLoad = false
        }

        var isLoading = false
        var listStates: [ListType: ListState] = [:]
        var showLoadingError = false
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

    var showLoadingError: Binding<Bool> {
        Binding { [weak self] in
            return self?.state.showLoadingError ?? false
        } set: { [weak self] value in
            guard let self = self else { return }
            Task {
                await self.reduce(.setShowLoadingError(value))
            }
        }
    }

    func searchText(for type: ListType) -> String {
        let listState = state.listStates[type]
        return listState?.searchText ?? ""
    }

    @MainActor func reduce(_ action: Action) {
        switch action {
        case let .search(type):
            Task {
                do {
                    try await load(type: type)
                } catch {
                    state.showLoadingError = true
                }
            }
        case let .load(type):
            Task {
                do {
                    try await load(type: type)
                } catch {
                    state.showLoadingError = true
                }
            }
        case let .loadMoreIfNeeded(type, link):
            Task {
                do {
                    try await loadMoreIfNeeded(type: type, link: link)
                } catch {
                    state.showLoadingError = true
                }
            }
        case let .changeSearchText(string, type):
            var listState = state.listStates[type] ?? State.ListState()
            listState.searchText = string
            state.listStates[type] = listState

            if string.isEmpty {
                reduce(.load(type))
            }
        case let .setShowLoadingError(show):
            state.showLoadingError = show
        case let .delete(_, link):
            Task {
                do {
                    try await delete(link: link)
                } catch {
                    state.showLoadingError = true
                }
            }
        }
    }

    var isLoading: Bool {
        state.isLoading
    }

    func didLoad(listType: ListType) -> Bool {
        state.listStates[listType]?.didLoad ?? false
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
        case .tags:
            return []
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
        listState.didLoad = true

        state.isLoading = true

        listState.links = try await client.load(
            filteredByTags: scopedTages(for: type),
            searchTerm: searchText(for: type)
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
            filteredByTags: scopedTages(for: type), searchTerm: searchText(for: type)
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

    @MainActor private func delete(link: Link) async throws {
        guard state.isLoading == false else { return }
        state.isLoading = true

        try await client.deleteLink(link: link)

        state.isLoading = false
    }
}
