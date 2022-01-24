//
//  AarloApp.swift
//  Shared
//
//  Created by martinhartl on 02.01.22.
//

import SwiftUI

struct AppState {
    var selectedLink: Link?
    var showLinkEditorSidebar = false
#if DEBUG
    static let stateMock = State(initialValue: AppState()).projectedValue
#endif
}

@main
struct AarloApp: App {
    let pasteboard = DefaultPasteboard()
    @State var appState = AppState()

    var body: some Scene {
        WindowGroup {
            NavigationView {
                InitialContentView(appState: $appState)
            }
            .tint(.tint)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Link") {
                    print("save new link")
                }
            }
            CommandGroup(after: .sidebar) {
                // TODO: Make title dynamic
                Button("Show Link Editor") {
                    appState.showLinkEditorSidebar.toggle()
                }
                .keyboardShortcut("0", modifiers: [.command, .option])
            }
            CommandMenu("Link") {
                Button("Copy link to clipboard") {
                    guard let selectedLink = appState.selectedLink else {
                        return
                    }

                    pasteboard.copyToPasteboard(string: selectedLink.url.absoluteString)
                }
                .keyboardShortcut("C", modifiers: [.command, .shift])
                .disabled(false)
            }
        }
#if os(macOS)
        Settings {
            SettingsView()
        }
#endif
    }
}
