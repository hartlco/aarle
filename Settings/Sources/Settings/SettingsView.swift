import SwiftUI
import Types

public struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var settingsState: SettingsState

    public init(settingsState: SettingsState) {
        self.settingsState = settingsState
    }

    public var body: some View {
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
                    selection: $settingsState.accountType
                ) {
                    ForEach(AccountType.allCases, id: \.self) {
                        Text($0.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                TextField(
                    "Key",
                    text: $settingsState.secret
                )
                .disableAutocorrection(true)
                if settingsState.accountType == .shaarli {
                    TextField(
                        "API Endpoint",
                        text: $settingsState.endpoint
                    )
                    .disableAutocorrection(true)
                    Text("Enter the endpoint in the following format: https://demo.shaarli.org/api/v1")
                        .font(.caption)
                }
                if settingsState.accountType == .linkding {
                    TextField(
                        "API Endpoint",
                        text: $settingsState.endpoint
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
