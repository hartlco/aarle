//
//  SettingsStore.swift
//  Aarlo
//
//  Created by martinhartl on 29.01.22.
//

import Foundation
import Combine
import SwiftUI
import KeychainAccess

enum AccountType: String, CaseIterable {
    case shaarli
    case pinboard
}

final class SettingsStore: ObservableObject {
    static let keychain = Keychain(service: "co.hartl.Aarle")
    static let keychainKey = "secret"
    static let endpointKey = "endpoint"
    static let servieKey = "servicekey"

    enum Action {
        case setSecret(String?)
        case setEndpoint(String?)
        case setAccountType(AccountType)
    }

    struct State {
        var accountType: AccountType
        var secret: String
        var endpoint: String
    }

    @Published private var state: State

    init() {
        let serviceString = Self.keychain[Self.servieKey]
        let accountType = AccountType(rawValue: serviceString ?? "") ?? .shaarli
        let secret = Self.keychain[Self.keychainKey] ?? ""
        let endpoint = Self.keychain[Self.endpointKey] ?? ""

        self._state = Published(
            initialValue: State(
                accountType: accountType, secret: secret, endpoint: endpoint
            )
        )
    }

    var isLoggedOut: Bool {
        switch state.accountType {
        case .shaarli:
            return state.secret.isEmpty || state.endpoint.isEmpty
        case .pinboard:
            return state.secret.isEmpty
        }
    }

    var secret: Binding<String?> {
        Binding { [weak self] in
            return self?.state.secret
        } set: { [weak self] secret in
            guard let self = self else { return }
            self.reduce(.setSecret(secret))
        }
    }

    var endpoint: Binding<String?> {
        Binding { [weak self] in
            return self?.state.endpoint
        } set: { [weak self] endpoint in
            guard let self = self else { return }
            self.reduce(.setEndpoint(endpoint))
        }
    }

    var accountType: Binding<AccountType> {
        Binding { [weak self] in
            return self?.state.accountType ?? .shaarli
        } set: { [weak self] accountType in
            guard let self = self else { return }
            self.reduce(.setAccountType(accountType))
        }
    }

    func reduce(_ action: Action) {
        switch action {
        case let .setSecret(secret):
            state.secret = secret ?? ""

            if state.secret.isEmpty {
                try? Self.keychain.remove(Self.keychainKey)
            } else {
                Self.keychain[Self.keychainKey] = state.secret
            }
        case let .setEndpoint(endpoint):
            state.endpoint = endpoint ?? ""

            if state.endpoint.isEmpty {
                try? Self.keychain.remove(Self.endpointKey)
            } else {
                Self.keychain[Self.endpointKey] = state.endpoint
            }
        case let .setAccountType(type):
            state.accountType = type
            Self.keychain[Self.servieKey] = state.accountType.rawValue
        }
    }
}
