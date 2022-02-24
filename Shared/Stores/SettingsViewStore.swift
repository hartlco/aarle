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
import ViewStore

extension Keychain {
    var accountType: AccountType {
        let serviceString = self[servieKey]
        return AccountType(rawValue: serviceString ?? "") ?? .shaarli
    }

    var secret: String {
        self[keychainKey] ?? ""
    }

    var endpoint: String {
        self[endpointKey] ?? ""
    }
}

typealias SettingsViewStore = ViewStore<SettingsState, SettingsAction, SettingsEnvironment>

extension SettingsViewStore {
    var isLoggedOut: Bool {
        switch self.accountType {
        case .shaarli:
            return self.secret.isEmpty || self.endpoint.isEmpty
        case .pinboard:
            return self.secret.isEmpty
        }
    }
}

struct SettingsState {
    var accountType: AccountType
    var secret: String
    var endpoint: String
}

extension SettingsState {
    init(keychain: Keychain) {
        self.accountType = keychain.accountType
        self.secret = keychain.secret
        self.endpoint = keychain.endpoint
    }
}

enum SettingsAction {
    case setSecret(String?)
    case setEndpoint(String?)
    case setAccountType(AccountType)
}

struct SettingsEnvironment {
    let keychain: Keychain
}

let keychainKey = "secret"
let endpointKey = "endpoint"
let servieKey = "servicekey"

let settingsReducer: ReduceFunction<SettingsState, SettingsAction, SettingsEnvironment> = { state, action, env in
    switch action {
    case let .setSecret(secret):
        state.secret = secret ?? ""

        if state.secret.isEmpty {
            try? env.keychain.remove(keychainKey)
        } else {
            env.keychain[keychainKey] = state.secret
        }
    case let .setEndpoint(endpoint):
        state.endpoint = endpoint ?? ""

        if state.endpoint.isEmpty {
            try? env.keychain.remove(endpointKey)
        } else {
            env.keychain[endpointKey] = state.endpoint
        }
    case let .setAccountType(type):
        state.accountType = type
        env.keychain[servieKey] = state.accountType.rawValue
    }

    return ActionResult.none
}

enum AccountType: String, CaseIterable {
    case shaarli
    case pinboard
}
