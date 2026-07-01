import Foundation
import Types
import Observation

@Observable
@MainActor
public final class SettingsState: SettingsStateProtocol {
    public var accountType: AccountType = .linkding {
        didSet {
            keychain.setAccountType(accountType: accountType)
        }
    }
    public var secret: String = "" {
        didSet {
            keychain.setSecret(secret: secret)
        }
    }
    public var endpoint: String = "" {
        didSet {
            keychain.setEndpoint(endpoint: endpoint)
        }
    }
    public var metadataEndpoint: String = "" {
        didSet {
            keychain.setMetadataEndpoint(endpoint: metadataEndpoint)
        }
    }
    public var autoSyncUnread: Bool = false {
        didSet {
            keychain.setAutoSyncUnread(enabled: autoSyncUnread)
            onAutoSyncChanged?()
        }
    }

    private let keychain: AarleKeychain
    public var onAutoSyncChanged: (() -> Void)?

    public init(keychain: AarleKeychain) {
        self.keychain = keychain
        self.accountType = keychain.accountType
        self.secret = keychain.secret
        self.endpoint = keychain.endpoint
        self.metadataEndpoint = keychain.metadataEndpoint
        self.autoSyncUnread = keychain.autoSyncUnread
    }

    public var isLoggedOut: Bool {
        self.secret.isEmpty || self.endpoint.isEmpty
    }
}
