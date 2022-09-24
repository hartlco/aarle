//
//  OverallAppState.swift
//  Aarle
//
//  Created by Martin Hartl on 01.09.22.
//

import Foundation
import Types
import AarleKeychain
import Settings
import Archive
import Navigation
import List

@MainActor final class TagState: ObservableObject {
    @Published var isLoading = false
    @Published var didLoad = false
    @Published var tags: [Tag] = []
    @Published var favoriteTags: [Tag]
    @Published var showLoadingError = false
    
    let client: BookmarkClient
    let userDefaults: UserDefaults

    init(
        client: BookmarkClient,
        userDefaults: UserDefaults,
        favoriteTags: [Tag]
    ) {
        self.client = client
        self.userDefaults = userDefaults
        self._favoriteTags = Published(initialValue: favoriteTags)
    }
    
    @MainActor func load() async {
        didLoad = true
        do {
            guard isLoading == false else { return }
            isLoading = true

            let newTags = try await client.loadTags().sorted(by: { tag1, tag2 in
                tag1.name < tag2.name
            })

            tags = newTags
            isLoading = false
        } catch {
            isLoading = false
        }
    }
    
    func addFavorite(tag: Tag) {
        userDefaults.favoriteTags.append(tag)
        favoriteTags = userDefaults.favoriteTags
    }
    
    func removeFavorite(tag: Tag) {
        userDefaults.favoriteTags.removeAll {
            tag == $0
        }
        favoriteTags = userDefaults.favoriteTags
    }
    
    func isTagFavorite(tag: Tag) -> Bool {
        favoriteTags.contains(tag)
    }
    
    func setShowLoadingError(show: Bool) {
        showLoadingError = show
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
}

@MainActor
final class OverallAppState: ObservableObject {
    let client: BookmarkClient

    init(
        client: BookmarkClient,
        userDefaults: UserDefaults = .suite,
        keychain: AarleKeychain
    ) {
        self.client = client
        self.tagState = TagState(
            client: client,
            userDefaults: userDefaults,
            favoriteTags: userDefaults.favoriteTags
        )
        self.settingsState = SettingsState(keychain: keychain)
        self.archiveState = ArchiveState(userDefaults: userDefaults)
        self.listState = List.ListState(client: client)
    }

    @Published var navigationState: NavigationState = .init()
    @Published var tagState: TagState
    @Published var settingsState: SettingsState
    @Published var archiveState: ArchiveState
    @Published var listState: List.ListState
}

extension UserDefaults {
    var favoriteTags: [Tag] {
        get {
            guard let data = data(forKey: #function),
                  let tags = try? PropertyListDecoder().decode([Tag].self, from: data)
            else {
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
