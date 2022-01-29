//
//  SettingsView.swift
//  Aarlo
//
//  Created by martinhartl on 03.01.22.
//

import SwiftUI
import KeychainAccess

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var settingsStore: SettingsStore


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
            TextField("Key", text: settingsStore.secret)
            TextField("API Endpoint:", text: settingsStore.endpoint)
            Button("Save") {
                presentationMode.dismiss()
                settingsStore.reduce(.login(accountType: .shaarli))
            }
        }
        .navigationTitle("Settings")
    }
}
