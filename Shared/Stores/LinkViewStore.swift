//
//  LinkStore.swift
//  Aarlo
//
//  Created by martinhartl on 05.01.22.
//

import Foundation
import Combine
import SwiftUI
import ViewStore

enum ListType: Hashable, Equatable, Sendable {
    case all
    case tags
    case tagScoped(Tag)

    var scopedTags:  [String] {
        switch self {
        case .all:
            return []
        case .tagScoped(let tag):
            return [tag.name]
        case .tags:
            return []
        }
    }
}

struct LinkState {
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

    func searchText(for type: ListType) -> String {
        let listState = listStates[type]
        return listState?.searchText ?? ""
    }
}

enum LinkAction {
    case load(ListType)
    case loadMoreIfNeeded(ListType, Link)
    case changeSearchText(String, listType: ListType)
    case search(ListType)
    case setShowLoadingError(Bool)
    case add(PostLink)
    case delete(Link)
    case update(Link)
}

struct LinkEnvironment {
    let client: BookmarkClient
}

typealias LinkViewStore = ViewStore<LinkState, LinkAction, LinkEnvironment>

extension LinkViewStore {
#if DEBUG
    static let mock = LinkViewStore(
        state: .init(),
        environment: .init(client: MockClient()),
        reduceFunction: linkReducer
    )
#endif

    func searchText(for type: ListType) -> String {
        let listState = self.listStates[type]
        return listState?.searchText ?? ""
    }

    func canLoadMore(for listType: ListType) -> Bool {
        self.listStates[listType]?.canLoadMore ?? false
    }

    func didLoad(listType: ListType) -> Bool {
        self.listStates[listType]?.didLoad ?? false
    }

    func link(for ID: String) -> Link? {
        for listStates in self.listStates {
            for link in listStates.value.links where link.id == ID {
                return link
            }
        }

        return nil
    }

    func links(for listType: ListType) -> [Link] {
        self.listStates[listType]?.links ?? []
    }
}

let linkReducer: ReduceFunction<LinkState, LinkAction, LinkEnvironment> = { state, action, env in
    switch action {
    case let .search(type):
        do {
            try await load(type: type, state: &state, client: env.client)
        } catch {
            state.showLoadingError = true
        }
    case let .load(type):
        do {
            try await load(type: type, state: &state, client: env.client)
        } catch {
            state.showLoadingError = true
        }
    case let .loadMoreIfNeeded(type, link):
        do {
            try await loadMoreIfNeeded(type: type, link: link, state: &state, client: env.client)
        } catch {
            state.showLoadingError = true
        }
    case let .changeSearchText(string, type):
        var listState = state.listStates[type] ?? LinkState.ListState()
        listState.searchText = string
        state.listStates[type] = listState

        if string.isEmpty {
            return .perform(.load(type))
        }
    case let .setShowLoadingError(show):
        state.showLoadingError = show
    case let .delete(link):
        do {
            try await delete(link: link, state: &state, client: env.client)
        } catch {
            state.showLoadingError = true
        }
    case let .update(link):
        do {
            try await update(link: link, state: &state, client: env.client)
        } catch {
            state.showLoadingError = true
        }
    case let .add(link):
        do {
            try await add(link: link, state: &state, client: env.client)
        } catch {
            state.showLoadingError = true
        }
    }

    return .none
}

@MainActor private func load(
    type: ListType,
    state: inout LinkState,
    client: BookmarkClient
) async throws {
    guard state.isLoading == false else { return }

    defer {
        state.isLoading = false
    }

    var listState = state.listStates[type] ?? LinkState.ListState()
    listState.didLoad = true

    state.isLoading = true

    listState.links = try await client.load(
        filteredByTags: type.scopedTags,
        searchTerm: state.searchText(for: type)
    )

    listState.canLoadMore = listState.links.count == client.pageSize
    state.listStates[type] = listState
}

@MainActor private func loadMoreIfNeeded(
    type: ListType,
    link: Link,
    state: inout LinkState,
    client: BookmarkClient
) async throws {
    guard state.isLoading == false else { return }

    var listState = state.listStates[type] ?? LinkState.ListState()

    guard link.id == listState.links.last?.id else { return }

    defer {
        state.isLoading = false
    }

    state.isLoading = true

    let links = try await client.loadMore(
        offset: listState.links.count,
        filteredByTags: type.scopedTags, searchTerm: state.searchText(for: type)
    )
    listState.links.append(contentsOf: links)

    listState.canLoadMore = links.count == client.pageSize
    state.listStates[type] = listState
}

@MainActor private func delete(link: Link, state: inout LinkState, client: BookmarkClient) async throws {
    func deleted(link: Link, from listState: LinkState.ListState) -> LinkState.ListState {
        var listState = listState
        listState.links.removeAll {
            link == $0
        }

        return listState
    }

    guard state.isLoading == false else { return }
    state.isLoading = true

    defer {
        state.isLoading = false
    }

    try await client.deleteLink(link: link)

    for (key, value) in state.listStates {
        state.listStates[key] = deleted(link: link, from: value)
    }
}

@MainActor private func add(link: PostLink, state: inout LinkState, client: BookmarkClient) async throws {
    guard state.isLoading == false else { return }
    state.isLoading = true

    defer {
        state.isLoading = false
    }

    try await client.createLink(link: link)
}

@MainActor private func update(link: Link, state: inout LinkState, client: BookmarkClient) async throws {
    func updated(link: Link, from listState: LinkState.ListState) -> LinkState.ListState {
        var listState = listState
        if let index = listState.links.firstIndex(where: { $0.id == link.id }) {
            listState.links[index] = link
        }

        return listState
    }

    guard state.isLoading == false else { return }
    state.isLoading = true

    defer {
        state.isLoading = false
    }

    try await client.updateLink(link: link)

    for (key, value) in state.listStates {
        state.listStates[key] = updated(link: link, from: value)
    }
}
