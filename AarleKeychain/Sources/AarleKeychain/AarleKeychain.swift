import KeychainAccess
import Types

extension Keychain: AarleKeychain {
    public var accountType: AccountType {
        let serviceString = self[servieKey]
        return AccountType(rawValue: serviceString ?? "") ?? .shaarli
    }
    
    public var secret: String {
        self[keychainKey] ?? ""
    }
    
    public var endpoint: String {
        self[endpointKey] ?? ""
    }
    
    public var metadataEndpoint: String {
        self[metadataEndpointKey] ?? ""
    }
    
    public func setAccountType(accountType: AccountType) {
        self[servieKey] = accountType.rawValue
    }
    
    public func setSecret(secret: String) {
        if secret.isEmpty {
            try? remove(keychainKey)
        } else {
            self[keychainKey] = secret
        }
    }
    
    public func setEndpoint(endpoint: String) {
        if endpoint.isEmpty {
            try? remove(endpointKey)
        } else {
            self[endpointKey] = endpoint
        }
    }
    
    public func setMetadataEndpoint(endpoint: String) {
        if endpoint.isEmpty {
            try? remove(metadataEndpointKey)
        } else {
            self[metadataEndpointKey] = endpoint
        }
    }

    public var autoSyncUnread: Bool {
        self[autoSyncUnreadKey] == "true"
    }

    public func setAutoSyncUnread(enabled: Bool) {
        self[autoSyncUnreadKey] = enabled ? "true" : "false"
    }
}

let keychainKey = "secret"
let endpointKey = "endpoint"
let metadataEndpointKey = "metadataEndpoint"
let servieKey = "servicekey"
let autoSyncUnreadKey = "autoSyncUnread"
