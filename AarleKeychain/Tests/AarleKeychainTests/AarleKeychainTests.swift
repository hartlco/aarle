import XCTest
@testable import AarleKeychain

final class AarleKeychainTests: XCTestCase {
    func testStorageKeysAreStable() {
        XCTAssertEqual(keychainKey, "secret")
        XCTAssertEqual(endpointKey, "endpoint")
        XCTAssertEqual(metadataEndpointKey, "metadataEndpoint")
        XCTAssertEqual(servieKey, "servicekey")
        XCTAssertEqual(autoSyncUnreadKey, "autoSyncUnread")
    }
}
