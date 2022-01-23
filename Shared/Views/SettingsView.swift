//
//  SettingsView.swift
//  Aarlo
//
//  Created by martinhartl on 03.01.22.
//

import SwiftUI
import KeychainAccess

// TODO: Move secret storage out of view
// TODO: Use https://developer.apple.com/documentation/swiftui/settings on macOS
struct SettingsView: View {
    static let keychain = Keychain(service: "co.hartl.Aarlo")
    static let keychainKey = "secret"
    static let endpointKey = "endpoint"

    @Environment(\.presentationMode) var presentationMode

    @State private var settingsField: String
    @State private var apiEndpointField: String

    init() {
        self._settingsField = State(initialValue: Self.keychain[string: Self.keychainKey] ?? "")
        self._apiEndpointField = State(initialValue: Self.keychain[string: Self.endpointKey] ?? "")
    }


    var body: some View {
        #if os(macOS)
        form
            .padding()
        #else
        NavigationView {
            form
        }
        #endif
    }

    var form: some View {
        Form {
            TextField("Key", text: $settingsField)
            TextField("API Endpoint:", text: $apiEndpointField)
            Button("Save") {
                presentationMode.dismiss()
                Self.keychain[Self.keychainKey] = settingsField
                Self.keychain[Self.endpointKey] = apiEndpointField
            }
        }
        .navigationTitle("Settings")
    }
}
