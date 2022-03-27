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
    @EnvironmentObject var settingsViewStore: SettingsViewStore

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
        // TODO: Add API endpoint info
        TabView {
            Form {
                Picker(
                    "Service",
                    selection: settingsViewStore.binding(get: \.accountType, send: { .setAccountType($0) })
                ) {
                    ForEach(AccountType.allCases, id: \.self) {
                        Text($0.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                TextField(
                    "Key",
                    text: settingsViewStore.binding(get: \.secret, send: { .setSecret($0) })
                )
                .disableAutocorrection(true)
                if settingsViewStore.accountType == .shaarli {
                    TextField(
                        "API Endpoint",
                        text: settingsViewStore.binding(get: \.endpoint, send: { .setEndpoint($0) })
                    )
                    .disableAutocorrection(true)
                    Text("Enter the endpoint in the following format: https://demo.shaarli.org/api/v1")
                        .font(.caption)
                }
                if settingsViewStore.accountType == .linkding {
                    TextField(
                        "API Endpoint",
                        text: settingsViewStore.binding(get: \.endpoint, send: { .setEndpoint($0) })
                    )
                    .disableAutocorrection(true)
                    // TODO: Update link
                    Text("Enter the endpoint in the following format: https://demo.shaarli.org/api/v1")
                        .font(.caption)
                }
            }
            .tabItem {
                Label("Account", systemImage: "person.crop.circle")
            }
            Form {
                Section {
                    Text("aarle is made by Martin Hartl, https://hartl.co")
                    Text("Open Source at https://github.com/hartlco/aarle")
                } header: {
                    Text("aarle").font(.headline)
                }
                Section {
                    Text("https://github.com/shaarli/Shaarli")
                } header: {
                    Text("Shaarli").font(.headline)
                }
            }
            .tabItem {
                Label("About", systemImage: "info.circle")
            }
        }
        .navigationTitle("Settings")
    }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        // TODO: Set mock env object
        SettingsView()
    }
}
#endif
