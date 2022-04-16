//
//  TagStore.swift
//  Aarlo
//
//  Created by martinhartl on 16.01.22.
//

import Foundation
import SwiftUI
import ViewStore

typealias TagViewStore = ViewStore<TagState, TagAction, TagEnvironment>

struct TagState {
    var isLoading = false
    var didLoad = false
    var tags: [Tag] = []
    var favoriteTags: [Tag] = []
    var showLoadingError = false
}

enum TagAction {
    case load
    case addFavorite(Tag)
    case removeFavorite(Tag)
    case setShowLoadingError(Bool)
}

struct TagEnvironment {
    let client: BookmarkClient
    let userDefaults: UserDefaults
}

let tagReducer: ReduceFunction<TagState, TagAction, TagEnvironment> = { state, action, env, handler in
    switch action {
    case .load:
        handler.handle(.change { state in state.didLoad = true })
        do {
            guard state.isLoading == false else { return }
            handler.handle(.change { state in state.isLoading = true })

            let newTags = try await env.client.loadTags().sorted(by: { tag1, tag2 in
                tag1.name < tag2.name
            })
            
            handler.handle(.change { state in state.tags = newTags })
            handler.handle(.change { state in state.isLoading = false })
        } catch {
            handler.handle(.change { state in state.isLoading = false })
        }
    case let .addFavorite(tag):
        env.userDefaults.favoriteTags.append(tag)
        handler.handle(.change { state in state.favoriteTags = env.userDefaults.favoriteTags })
    case let .removeFavorite(favoriteTag):
        env.userDefaults.favoriteTags.removeAll { tag in
            tag == favoriteTag
        }
        handler.handle(.change { state in state.favoriteTags = env.userDefaults.favoriteTags })
    case let .setShowLoadingError(show):
        handler.handle(.change { state in state.showLoadingError = show })
    }
}

extension TagViewStore {
#if DEBUG
    static let mock = TagViewStore(
        state: TagState(),
        environment: TagEnvironment(client: MockClient(),
                                    userDefaults: .standard),
        reduceFunction: tagReducer
    )
#endif

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
        self.favoriteTags.contains(tag)
    }
}

extension UserDefaults {
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
