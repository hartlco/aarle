import XCTest
@testable import Tag
import Types

final class TagTests: XCTestCase {
    @MainActor
    func testTagStringHelpers() {
        let state = TagState(
            client: MockBookmarkClient(),
            userDefaults: UserDefaults(suiteName: UUID().uuidString)!,
            favoriteTags: []
        )
        let tag = Types.Tag(name: "swift")

        XCTAssertTrue(state.tagsString("ios swift macos", contains: tag))
        XCTAssertEqual(state.addingTag(tag, toTagsString: "ios"), "ios swift")
        XCTAssertEqual(state.removingTag(tag, fromTagsString: "ios swift macos"), "ios macos")
    }

    @MainActor
    func testLoadSortsTagsByName() async {
        let state = TagState(
            client: MockBookmarkClient(tags: [
                Types.Tag(name: "zeta"),
                Types.Tag(name: "alpha")
            ]),
            userDefaults: UserDefaults(suiteName: UUID().uuidString)!,
            favoriteTags: []
        )

        await state.load()

        XCTAssertEqual(state.tags.map(\.name), ["alpha", "zeta"])
    }
}

private struct MockBookmarkClient: BookmarkClient {
    var tags: [Types.Tag] = []
    let pageSize = 100

    func load(filteredByTags tags: [String], searchTerm: String?) async throws -> [Link] {
        []
    }

    func loadMore(offset: Int, filteredByTags tags: [String], searchTerm: String?) async throws -> [Link] {
        []
    }

    func createLink(link: PostLink) async throws {}
    func updateLink(link: Link) async throws {}
    func deleteLink(link: Link) async throws {}
    func loadTags() async throws -> [Types.Tag] { tags }
}
