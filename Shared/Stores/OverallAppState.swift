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

// TODO: check if all setter side effects were migrated
enum ListType: Hashable, Equatable, Sendable {
    case all
    case tagScoped(Tag)
    case downloaded

    var scopedTags: [String] {
        switch self {
        case .all:
            return []
        case let .tagScoped(tag):
            return [tag.name]
        case .downloaded:
            return []
        }
    }
}

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

final class NavigationState: ObservableObject {
    #if os(macOS)
        @Published var selectedListType: ListType = .all {
            didSet {
                print("Didset selectedListType: \(selectedListType)")
            }
        }
    #else
        @Published var selectedListType: ListType? {
            didSet {
                print("Didset selectedListType: \(selectedListType)")
            }
        }
    #endif

    @Published var showsSettings = false {
        didSet {
            if showsSettings {
                #if os(macOS)
                    WindowRoutes.settings.open()
                #endif
            }
        }
    }

    @Published var selectedLink: Link? {
        didSet {
            print("Didset selectedLink: \(selectedLink?.url.absoluteString ?? "No URL")")
        }
    }
    
    @Published var showLinkEditorSidebar = false
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
    }

    @Published var navigationState: NavigationState = .init()
    @Published var tagState: TagState
    @Published var settingsState: SettingsState
    @Published var archiveState: ArchiveState

    @Published var selectedArchiveLink: ArchiveLink?
    @Published var presentedEditLink: Link?
    @Published var showsAddView = false {
        didSet {
            if showsAddView {
                #if os(macOS)
                    WindowRoutes.addLink.open()
                #endif
            }
        }
    }

    struct ListState {
        var links: [Link] = []
        var tagScope: String?
        var canLoadMore = false
        var searchText = ""
        var didLoad = false
    }

    @Published var isLoading = false
    @Published var listStates: [ListType: ListState] = [:]
    @Published var showLoadingError = false

    func searchText(for type: ListType) -> String {
        let listState = listStates[type]
        return listState?.searchText ?? ""
    }

    func setSearchText(text: String, for type: ListType) {
        listStates[type]?.searchText = text
    }

    func canLoadMore(for listType: ListType) -> Bool {
        listStates[listType]?.canLoadMore ?? false
    }

    func didLoad(listType: ListType) -> Bool {
        listStates[listType]?.didLoad ?? false
    }

    func links(for listType: ListType) -> [Link] {
        listStates[listType]?.links ?? []
    }

    func link(for ID: String) -> Link? {
        for listStates in listStates {
            for link in listStates.value.links where link.id == ID {
                return link
            }
        }

        return nil
    }

    func loadSearch(for type: ListType) async {
        do {
            guard isLoading == false else { return }

            var listState = listStates[type] ?? ListState()
            listState.didLoad = true

            isLoading = true

            listState.links = try await client.load(
                filteredByTags: type.scopedTags,
                searchTerm: searchText(for: type)
            )

            listState.canLoadMore = listState.links.count == client.pageSize
            listStates[type] = listState
            isLoading = false
        } catch {
            showLoadingError = true
            isLoading = false
        }
    }

    func loadMoreIfNeeded(type: ListType, link: Link) async {
        do {
            guard isLoading == false else { return }

            var listState = listStates[type] ?? ListState()

            guard link.id == listState.links.last?.id else { return }

            isLoading = true

            let links = try await client.loadMore(
                offset: listState.links.count,
                filteredByTags: type.scopedTags, searchTerm: searchText(for: type)
            )
            listState.links.append(contentsOf: links)

            listState.canLoadMore = links.count == client.pageSize
            listStates[type] = listState
            isLoading = false
        } catch {
            showLoadingError = true
        }
    }

    func changeSearchText(string: String, type: ListType) async {
        var listState = listStates[type] ?? ListState()
        listState.searchText = string

        listStates[type] = listState

        if string.isEmpty {
            await loadSearch(for: type)
        }
    }

    func delete(link: Link) async {
        func deleted(link: Link, from listState: ListState) -> ListState {
            var listState = listState
            listState.links.removeAll {
                link == $0
            }

            return listState
        }

        guard isLoading == false else { return }
        isLoading = true

        do {
            try await client.deleteLink(link: link)

            for (key, value) in listStates {
                listStates[key] = deleted(link: link, from: value)
            }

            isLoading = false
        } catch {
            isLoading = false
            showLoadingError = true
        }
    }

    func update(link: Link) async {
        func updated(link: Link, from listState: ListState) -> ListState {
            var listState = listState
            if let index = listState.links.firstIndex(where: { $0.id == link.id }) {
                listState.links[index] = link
            }

            return listState
        }

        guard isLoading == false else { return }
        isLoading = true

        do {
            try await client.updateLink(link: link)
            for (key, value) in listStates {
                listStates[key] = updated(link: link, from: value)
            }
            isLoading = false
        } catch {
            isLoading = false
            showLoadingError = true
        }
    }

    func add(link: PostLink) async {
        do {
            guard isLoading == false else { return }
            isLoading = true

            try await client.createLink(link: link)
            let tempLink = Link(
                id: UUID().uuidString,
                url: link.url,
                title: link.title,
                description: link.description,
                tags: link.tags,
                private: link.private,
                created: link.created
            )

            for (key, value) in listStates {
                switch key {
                case .all:
                    var value = value
                    value.links.insert(tempLink, at: 0)
                    listStates[key] = value
                case let .tagScoped(tag):
                    guard tempLink.tags.contains(tag.name) else {
                        continue
                    }

                    var value = value
                    value.links.insert(tempLink, at: 0)
                    listStates[key] = value
                case .downloaded:
                    continue
                }
            }

            isLoading = false
        } catch {
            isLoading = false
            showLoadingError = true
        }
    }
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
