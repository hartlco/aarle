import XCTest
@testable import Navigation
import Types

final class NavigationTests: XCTestCase {
    func testDetailDestinationURL() {
        let url = URL(string: "https://example.com")!
        let link = Link(
            id: "1",
            url: url,
            title: "Example",
            tags: [],
            private: false,
            created: Date()
        )

        XCTAssertEqual(DetailNavigationDestination.link(link).url, url)
        XCTAssertNil(DetailNavigationDestination.empty.url)
        XCTAssertTrue(DetailNavigationDestination.link(link).isLinkSelected)
        XCTAssertFalse(DetailNavigationDestination.empty.isLinkSelected)
    }

    @MainActor
    func testNavigationStateDefaultsToAllLinks() {
        let state = NavigationState()

        XCTAssertEqual(state.selectedListType, .all)
        XCTAssertFalse(state.showsSettings)
    }
}
