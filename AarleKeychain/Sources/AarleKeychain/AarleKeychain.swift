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
}

let keychainKey = "secret"
let endpointKey = "endpoint"
let servieKey = "servicekey"
