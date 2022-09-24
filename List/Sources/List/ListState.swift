import Foundation
import Types

public final class ListState: ObservableObject {
    @Published public var isLoading = false
    @Published public var showLoadingError = false
    
    private let client: BookmarkClient
    
    public init(client: BookmarkClient) {
        self.client = client
    }
    
    private struct InternalListState {
        var links: [Link] = []
        var tagScope: String?
        var canLoadMore = false
        var searchText = ""
        var didLoad = false
    }

    @Published private var listStates: [ListType: InternalListState] = [:]

    public func searchText(for type: ListType) -> String {
        let listState = listStates[type]
        return listState?.searchText ?? ""
    }

    public func setSearchText(text: String, for type: ListType) {
        listStates[type]?.searchText = text
    }

    public func canLoadMore(for listType: ListType) -> Bool {
        listStates[listType]?.canLoadMore ?? false
    }

    public func didLoad(listType: ListType) -> Bool {
        listStates[listType]?.didLoad ?? false
    }

    public func links(for listType: ListType) -> [Link] {
        listStates[listType]?.links ?? []
    }

    public func link(for ID: String) -> Link? {
        for listStates in listStates {
            for link in listStates.value.links where link.id == ID {
                return link
            }
        }

        return nil
    }

    public func loadSearch(for type: ListType) async {
        do {
            guard isLoading == false else { return }

            var listState = listStates[type] ?? InternalListState()
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

    public func loadMoreIfNeeded(type: ListType, link: Link) async {
        do {
            guard isLoading == false else { return }

            var listState = listStates[type] ?? InternalListState()

            guard link.id == listState.links.last?.id else { return }

            self.isLoading = true

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

    public func changeSearchText(string: String, type: ListType) async {
        var listState = listStates[type] ?? InternalListState()
        listState.searchText = string

        listStates[type] = listState

        if string.isEmpty {
            await loadSearch(for: type)
        }
    }

    public func delete(link: Link) async {
        func deleted(link: Link, from listState: InternalListState) -> InternalListState {
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

    public func update(link: Link) async {
        func updated(link: Link, from listState: InternalListState) -> InternalListState {
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

    public func add(link: PostLink) async {
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
