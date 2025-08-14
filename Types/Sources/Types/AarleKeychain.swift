public protocol AarleKeychain {
    var accountType: AccountType { get }

    var secret: String { get }

    var endpoint: String { get }

    var metadataEndpoint: String { get }

    func setAccountType(accountType: AccountType)

    func setSecret(secret: String)

    func setEndpoint(endpoint: String)

    func setMetadataEndpoint(endpoint: String)
}
