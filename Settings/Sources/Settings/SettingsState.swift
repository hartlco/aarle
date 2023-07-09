import Foundation
import Types
import Observation

@Observable
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

    private let keychain: AarleKeychain

    public init(keychain: AarleKeychain) {
        self.keychain = keychain
        self.accountType = keychain.accountType
        self.secret = keychain.secret
        self.endpoint = keychain.endpoint
    }

    public var isLoggedOut: Bool {
        switch self.accountType {
        case .shaarli, .linkding:
            return self.secret.isEmpty || self.endpoint.isEmpty
        case .pinboard:
            return self.secret.isEmpty
        }
    }
}
