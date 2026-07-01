import XCTest
@testable import Archive

final class ArchiveTests: XCTestCase {
    @MainActor
    func testInitialStateUsesStoredArchives() {
        let suiteName = "ArchiveTests-\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        defer {
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        let state = ArchiveState(userDefaults: userDefaults)

        XCTAssertTrue(state.archiveLinks.isEmpty)
        XCTAssertEqual(state.failedCount, 0)
        XCTAssertEqual(state.downloadedCount, 0)
    }
}
