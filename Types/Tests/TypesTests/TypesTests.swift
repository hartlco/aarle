import XCTest
@testable import Types

final class TypesTests: XCTestCase {
    func testListTypeScopedTags() {
        let tag = Tag(name: "swift", occurrences: 2)

        XCTAssertEqual(ListType.all.scopedTags, [])
        XCTAssertEqual(ListType.tagScoped(tag).scopedTags, ["swift"])
        XCTAssertEqual(ListType.tags(selectedTag: tag).scopedTags, ["swift"])
        XCTAssertEqual(ListType.tags(selectedTag: nil).scopedTags, [])
    }

    func testAccountTypeDefaults() {
        XCTAssertEqual(AccountType.allCases, [.linkding])
    }
}
