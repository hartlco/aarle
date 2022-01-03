//
//  SettingsView.swift
//  Aarlo
//
//  Created by martinhartl on 03.01.22.
//

import SwiftUI
import KeychainAccess

// TODO: Move secret storage out of view
struct SettingsView: View {
    static let keychain = Keychain(accessGroup: "secret")
    static let keychainKey = "secret"

    @Binding var showsSettings: Bool

    @State private var settingsField = ""

    init(showsSettings: Binding<Bool>) {
        self._showsSettings = showsSettings

        settingsField = Self.keychain[string: Self.keychainKey] ?? ""
    }


    var body: some View {
        VStack {
            Text("Settings")
            TextField("Key", text: $settingsField)
            Button("Save") {
                showsSettings = false
                Self.keychain[Self.keychainKey] = settingsField
            }
        }
        .padding()
    }
}
