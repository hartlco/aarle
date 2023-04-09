import Foundation
import Types

@MainActor
public final class TagState: ObservableObject {
    @Published public var isLoading = false
    @Published public var didLoad = false
    @Published public var tags: [Tag] = []
    @Published public var favoriteTags: [Tag]
    @Published public var showLoadingError = false

    let client: BookmarkClient
    let userDefaults: UserDefaults

    public init(
        client: BookmarkClient,
        userDefaults: UserDefaults,
        favoriteTags: [Tag]
    ) {
        self.client = client
        self.userDefaults = userDefaults
        self._favoriteTags = Published(initialValue: favoriteTags)
    }

    @MainActor
    public func load() async {
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

    public func addFavorite(tag: Tag) {
        userDefaults.favoriteTags.append(tag)
        favoriteTags = userDefaults.favoriteTags
    }

    public func removeFavorite(tag: Tag) {
        userDefaults.favoriteTags.removeAll {
            tag == $0
        }
        favoriteTags = userDefaults.favoriteTags
    }

    public func toggleFavorite(tag: Tag) {
        if isTagFavorite(tag: tag) {
            removeFavorite(tag: tag)
        } else {
            addFavorite(tag: tag)
        }
    }

    public func isTagFavorite(tag: Tag) -> Bool {
        favoriteTags.contains(tag)
    }

    public func tagsString(_ tagsString: String, contains tag: Tag) -> Bool {
        tagsString
            .components(separatedBy: " ")
            .contains(tag.name)
    }

    public func addingTag(_ tag: Tag, toTagsString tagsString: String) -> String {
        var components = tagsString.components(separatedBy: " ")
        components.append(tag.name)
        return components.joined(separator: " ")
    }

    public func removingTag(_ tag: Tag, fromTagsString tagsString: String) -> String {
        var components = tagsString.components(separatedBy: " ")
        components.removeAll { component in
            component == tag.name
        }
        return components.joined(separator: " ")
    }
}

public extension UserDefaults {
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
