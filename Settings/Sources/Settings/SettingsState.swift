import Foundation
import Types

public final class SettingsState: ObservableObject, SettingsStateProtocol {
    @Published public var accountType: AccountType {
        didSet {
            keychain.setAccountType(accountType: accountType)
        }
    }
    @Published public var secret: String {
        didSet {
            keychain.setSecret(secret: secret)
        }
    }
    @Published public var endpoint: String {
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
