//
//  AarloApp.swift
//  Shared
//
//  Created by martinhartl on 02.01.22.
//

import KeychainAccess
import SwiftUI
import SwiftUIX
import ViewStore
import Settings

@main
struct AarleApp: App {
    static let keyChain = Keychain(service: "co.hartl.Aarle")

    let pasteboard = DefaultPasteboard()

    @StateObject var archiveViewStore = ArchiveViewStore(
        state: ArchiveState(archiveLinks: UserDefaults.suite.archiveLinks),
        environment: ArchiveEnvironment(archiveService: .init(userDefaults: .suite)),
        reduceFunction: archiveReducer
    )

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
            .environmentObject(archiveViewStore)
            .environmentObject(overallAppState)
        }
        // TODO: Refactor out creation of commands
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Link") {
                    overallAppState.showsAddView = true
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
                        if let selectedListType = overallAppState.navigationState.selectedListType {
                            await overallAppState.loadSearch(for: selectedListType)
                        }
                    }
                    Task {
                        await overallAppState.tagState.load()
                    }
                }
                .keyboardShortcut("R", modifiers: [.command])
            }
            CommandMenu("Link") {
                // TODO: Use same implementation as right click menu
                Button("Edit link") {
                    guard let selectedLinkID = overallAppState.navigationState.selectedLink?.id,
                          let selectedLink = overallAppState.link(for: selectedLinkID)
                    else {
                        return
                    }

                    overallAppState.presentedEditLink = selectedLink
                }
                .keyboardShortcut("e", modifiers: [.command])
                .disabled(overallAppState.navigationState.selectedLink == nil)
                Button("Copy link to clipboard") {
                    guard let selectedLinkID = overallAppState.navigationState.selectedLink?.id,
                          let selectedLink = overallAppState.link(for: selectedLinkID)
                    else {
                        return
                    }

                    pasteboard.copyToPasteboard(string: selectedLink.url.absoluteString)
                }
                .keyboardShortcut("C", modifiers: [.command, .shift])
                .disabled(overallAppState.navigationState.selectedLink == nil)
                Button("Delete") {
                    guard let selectedLinkID = overallAppState.navigationState.selectedLink?.id,
                          let selectedLink = overallAppState.link(for: selectedLinkID)
                    else {
                        return
                    }

                    // TODO: Clear selection after delete
                    Task {
                        await overallAppState.delete(link: selectedLink)
                    }
                }
                .keyboardShortcut(.delete, modifiers: [.command])
                .disabled(overallAppState.navigationState.selectedLink == nil)
            }
        }
        LinkAddScene(
            overallAppState: overallAppState
        ).handlesExternalEvents(matching: Set([WindowRoutes.addLink.rawValue]))
        LinkEditScene(
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
                overallAppState.showsAddView = false
            }
            .environmentObject(overallAppState)
        }
    }
}

struct LinkEditScene: Scene {
    @ObservedObject var overallAppState: OverallAppState

    var body: some Scene {
        WindowGroup {
            if let presentedEditLink = overallAppState.presentedEditLink {
                LinkEditView(
                    link: presentedEditLink,
                    showCancelButton: false
                ).onDisappear {
                    overallAppState.showsAddView = false
                }
                .environmentObject(overallAppState)
            } else {
                Text("Edit Link")
            }
        }
    }
}
