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

@main
struct AarleApp: App {
    static let keyChain = Keychain(service: "co.hartl.Aarle")

    let pasteboard = DefaultPasteboard()

    @State var overallAppState = OverallAppState(
        client: UniversalClient(keychain: keyChain),
        keychain: keyChain
    )

    var body: some Scene {
        WindowGroup {
            InitialContentView()
            .environment(overallAppState)
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
                .disabled(overallAppState.navigationState.selectedDetailDestination?.isLinkSelected != true)
            }
            CommandMenu("List") {
                Button("Refresh") {
                    Task {
                        guard let selectedListType = overallAppState.navigationState.selectedListType else { return }
                        await overallAppState.listState.loadSearch(for: selectedListType)
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
                archiveState: overallAppState.archiveState,
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
    var overallAppState: OverallAppState

    var body: some Scene {
        WindowGroup {
            LinkAddView(
                overallAppState: overallAppState
            ).onDisappear {
                overallAppState.navigationState.showsAddView = false
            }
        }
    }
}

struct LinkEditScene: Scene {
    var navigationState: NavigationState
    var overallAppState: OverallAppState

    var body: some Scene {
        WindowGroup {
            if let presentedEditLink = navigationState.presentedEditLink {
                LinkEditView(
                    overallAppState: overallAppState,
                    link: presentedEditLink,
                    showCancelButton: false
                ).onDisappear {
                    navigationState.showsAddView = false
                }
            } else {
                Text("Edit Link 2")
            }
        }
    }
}
