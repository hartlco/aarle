import Foundation

@MainActor
public protocol SettingsStateProtocol: ObservableObject {
    var accountType: AccountType { get }
    var isLoggedOut: Bool { get }
}
