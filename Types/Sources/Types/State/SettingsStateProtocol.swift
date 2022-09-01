import Foundation

public protocol SettingsStateProtocol: ObservableObject {
    var accountType: AccountType { get }
    var isLoggedOut: Bool { get }
}
