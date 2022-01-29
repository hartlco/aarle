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
                }
                Button("Save") {
                    presentationMode.dismiss()
                    settingsStore.reduce(.login)
                }
            }
            .tabItem {
                Label("Account", systemImage: "person.crop.circle")
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
