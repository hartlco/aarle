//
//  TagStore.swift
//  Aarlo
//
//  Created by martinhartl on 16.01.22.
//

import Foundation
import SwiftUI

final class TagStore: ObservableObject {
    enum Action {
        case load
        case addFavorite(Tag)
        case removeFavorite(Tag)
        case setShowLoadingError(Bool)
    }

    struct State {
        var isLoading = false
        var didLoad = false
        var tags: [Tag] = []
        var favoriteTags: [Tag] = []
        var showLoadingError = false
    }

    @Published private var state: State

    private let client: BookmarkClient
    private let userDefaults: UserDefaults


#if DEBUG
    static let mock = TagStore(client: MockClient())
#endif

    init(
        client: BookmarkClient,
        userDefaults: UserDefaults = .suite
    ) {
        self.client = client
        self.userDefaults = userDefaults
        self._state = Published(
            initialValue: State(
                isLoading: false,
                tags: [],
                favoriteTags: userDefaults.favoriteTags
            )
        )
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

    var favoriteTags: [Tag] {
        state.favoriteTags
    }

    var tags: [Tag] {
        state.tags
    }

    var isLoading: Bool {
        state.isLoading
    }

    var didLoad: Bool {
        state.didLoad
    }

    @MainActor func reduce(_ action: Action) {
        switch action {
        case .load:
            state.didLoad = true
            Task {
                do {
                    try await loadTags()
                } catch {
                    state.showLoadingError = true
                }
            }
        case let .addFavorite(tag):
            add(favoriteTag: tag)
        case let .removeFavorite(tag):
            remove(favoriteTag: tag)
        case let .setShowLoadingError(show):
            state.showLoadingError = show
        }
    }

    @MainActor private func loadTags() async throws {
        guard state.isLoading == false else { return }
        state.isLoading = true

        state.tags = try await client.loadTags().sorted(by: { tag1, tag2 in
            tag1.name < tag2.name
        })

        state.isLoading = false
    }

    func tagsString(_ tagsString: String, contains tag: Tag) -> Bool {
        tagsString
            .components(separatedBy: " ")
            .contains(tag.name)
    }

    func addingTag(_ tag: Tag, toTagsString tagsString: String) -> String {
        var components = tagsString.components(separatedBy: " ")
        components.append(tag.name)
        return components.joined(separator: " ")
    }

    func removingTag(_ tag: Tag, fromTagsString tagsString: String) -> String {
        var components = tagsString.components(separatedBy: " ")
        components.removeAll { component in
            component == tag.name
        }
        return components.joined(separator: " ")
    }

    func isTagFavorite(tag: Tag) -> Bool {
        state.favoriteTags.contains(tag)
    }

    private func add(favoriteTag: Tag) {
        userDefaults.favoriteTags.append(favoriteTag)
        state.favoriteTags = userDefaults.favoriteTags
    }

    private func remove(favoriteTag: Tag) {
        userDefaults.favoriteTags.removeAll { tag in
            tag == favoriteTag
        }
        state.favoriteTags = userDefaults.favoriteTags
    }
}

private extension UserDefaults {
    var favoriteTags: [Tag] {
        get {
            guard let data = data(forKey: #function),
                  let tags = try? PropertyListDecoder().decode([Tag].self, from: data) else {
                    return []
                }
            return tags
        }
        set {
            guard let data = try? PropertyListEncoder().encode(newValue) else {
                return
            }

            set(data, forKey: #function)
        }
    }
}
