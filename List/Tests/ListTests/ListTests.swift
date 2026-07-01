import XCTest
@testable import List
import Types

final class ListTests: XCTestCase {
    @MainActor
    func testLoadSearchStoresLinks() async {
        let link = Link(
            id: "1",
            url: URL(string: "https://example.com")!,
            title: "Example",
            tags: ["swift"],
            private: false,
            created: Date()
        )
        let state = ListState(client: MockBookmarkClient(links: [link]))

        await state.loadSearch(for: .all)

        XCTAssertTrue(state.didLoad(listType: .all))
        XCTAssertEqual(state.links(for: .all), [link])
        XCTAssertFalse(state.canLoadMore(for: .all))
    }
}

private struct MockBookmarkClient: BookmarkClient {
    let links: [Link]
    let pageSize = 100

    func load(filteredByTags tags: [String], searchTerm: String?) async throws -> [Link] {
        links
    }

    func loadMore(offset: Int, filteredByTags tags: [String], searchTerm: String?) async throws -> [Link] {
        []
    }

    func createLink(link: PostLink) async throws {}
    func updateLink(link: Link) async throws {}
    func deleteLink(link: Link) async throws {}
    func loadTags() async throws -> [Tag] { [] }
}
