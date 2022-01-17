//
//  TagStore.swift
//  Aarlo
//
//  Created by martinhartl on 16.01.22.
//

import Foundation

final class TagStore: ObservableObject {
    @Published var isLoading: Bool
    @Published var tags: [Tag]
    @Published var favoriteTags: [Tag] = []

    private let client: ShaarliClient
    private let userDefaults: UserDefaults


#if DEBUG
    static let mock = TagStore(client: ShaarliClient())
#endif

    init(
        client: ShaarliClient,
        userDefaults: UserDefaults = .standard
    ) {
        self.client = client
        self.tags = []
        self.userDefaults = userDefaults
        self.isLoading = false

        self.favoriteTags = userDefaults.favoriteTags
    }

    @MainActor func loadTags() async throws {
        guard isLoading == false else { return }
        isLoading = true

        tags = try await client.loadTags().sorted(by: { tag1, tag2 in
            tag1.name < tag2.name
        })

        isLoading = false
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
        favoriteTags.contains(tag)
    }

    func add(favoriteTag: Tag) {
        userDefaults.favoriteTags.append(favoriteTag)
        self.favoriteTags = userDefaults.favoriteTags
    }

    func remove(favoriteTag: Tag) {
        userDefaults.favoriteTags.removeAll { tag in
            tag == favoriteTag
        }
        self.favoriteTags = userDefaults.favoriteTags
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
