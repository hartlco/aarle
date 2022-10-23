//
//  AarloApp.swift
//  Shared
//
//  Created by martinhartl on 02.01.22.
//

import KeychainAccess
import SwiftUI
import SwiftUIX
import Settings
import Types
import List
import Navigation

// TODO: Split up all states
@main
struct AarleApp: App {
    static let keyChain = Keychain(service: "co.hartl.Aarle")

    let pasteboard = DefaultPasteboard()

    @StateObject var overallAppState = OverallAppState(
        client: UniversalClient(keychain: keyChain),
        keychain: keyChain
    )

    var body: some Scene {
        WindowGroup {
            InitialContentView(
                navigationState: overallAppState.navigationState,
                tagState: overallAppState.tagState
            )
            .environmentObject(overallAppState)
        }
        // TODO: Refactor out creation of commands
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Link") {
                    overallAppState.navigationState.showsAddView = true
                }
                .keyboardShortcut("n", modifiers: [.command])
            }
            CommandGroup(after: .sidebar) {
                // TODO: Make title dynamic
                Button("Show Link Editor") {
                    overallAppState.navigationState.showLinkEditorSidebar.toggle()
                }
                .keyboardShortcut("0", modifiers: [.command, .option])
                .disabled(overallAppState.navigationState.selectedLink == nil)
            }
            CommandMenu("List") {
                Button("Refresh") {
                    Task {
#if os(macOS)
                        await overallAppState.listState.loadSearch(for: overallAppState.navigationState.selectedListType)
#else
                        guard let selectedListType = overallAppState.navigationState.selectedListType else { return }
                        await overallAppState.listState.loadSearch(for: selectedListType)
#endif
                    }
                    Task {
                        await overallAppState.tagState.load()
                    }
                }
                .keyboardShortcut("R", modifiers: [.command])
            }
            LinkCommands(
                navigationState: overallAppState.navigationState,
                listState: overallAppState.listState,
                pasteboard: pasteboard
            )
        }
        LinkAddScene(
            overallAppState: overallAppState
        ).handlesExternalEvents(matching: Set([WindowRoutes.addLink.rawValue]))
        LinkEditScene(
            navigationState: overallAppState.navigationState,
            overallAppState: overallAppState
        ).handlesExternalEvents(matching: Set([WindowRoutes.editLink.rawValue]))
        #if os(macOS)
            WindowGroup {
                SettingsView(settingsState: overallAppState.settingsState)
                    .onDisappear {
                        overallAppState.navigationState.showsSettings = false
                    }
                    .frame(width: 500, height: 300)
            }
            .handlesExternalEvents(matching: Set([WindowRoutes.settings.rawValue]))
            Settings {
                SettingsView(settingsState: overallAppState.settingsState)
                    .frame(width: 500, height: 300)
            }
        #endif
    }
}

struct LinkAddScene: Scene {
    @ObservedObject var overallAppState: OverallAppState

    var body: some Scene {
        WindowGroup {
            LinkAddView().onDisappear {
                overallAppState.navigationState.showsAddView = false
            }
            .environmentObject(overallAppState)
        }
    }
}

struct LinkEditScene: Scene {
    @ObservedObject var navigationState: NavigationState
    @ObservedObject var overallAppState: OverallAppState

    var body: some Scene {
        WindowGroup {
            if let presentedEditLink = navigationState.presentedEditLink {
                LinkEditView(
                    link: presentedEditLink,
                    showCancelButton: false
                ).onDisappear {
                    navigationState.showsAddView = false
                }
                .environmentObject(overallAppState)
            } else {
                Text("Edit Link 2")
            }
        }
    }
}
