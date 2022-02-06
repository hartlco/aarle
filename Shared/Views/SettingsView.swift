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
        // TODO: Add API endpoint info
        TabView {
            Form {
                Picker("Service", selection: settingsStore.accountType) {
                    ForEach(AccountType.allCases, id: \.self) {
                        Text($0.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                TextField("Key", text: settingsStore.secret)
                if settingsStore.accountType.wrappedValue == .shaarli {
                    TextField("API Endpoint:", text: settingsStore.endpoint)
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
        SettingsView().environmentObject(SettingsStore())
    }
}
#endif
