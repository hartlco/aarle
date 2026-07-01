import XCTest
@testable import Settings
import Types

final class SettingsTests: XCTestCase {
    @MainActor
    func testIsLoggedOutReflectsMissingCredentials() {
        let keychain = MockKeychain(secret: "", endpoint: "")
        let state = SettingsState(keychain: keychain)

        XCTAssertTrue(state.isLoggedOut)

        state.secret = "token"
        state.endpoint = "https://example.com"

        XCTAssertFalse(state.isLoggedOut)
        XCTAssertEqual(keychain.secret, "token")
        XCTAssertEqual(keychain.endpoint, "https://example.com")
    }
}

private final class MockKeychain: AarleKeychain {
    var accountType: AccountType = .linkding
    var secret: String
    var endpoint: String
    var metadataEndpoint = ""
    var autoSyncUnread = false

    init(secret: String, endpoint: String) {
        self.secret = secret
        self.endpoint = endpoint
    }

    func setAccountType(accountType: AccountType) {
        self.accountType = accountType
    }

    func setSecret(secret: String) {
        self.secret = secret
    }

    func setEndpoint(endpoint: String) {
        self.endpoint = endpoint
    }

    func setMetadataEndpoint(endpoint: String) {
        metadataEndpoint = endpoint
    }

    func setAutoSyncUnread(enabled: Bool) {
        autoSyncUnread = enabled
    }
}
