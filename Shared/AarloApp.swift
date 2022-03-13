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

@main
struct AarleApp: App {
    static let keyChain = Keychain(service: "co.hartl.Aarle")

    let pasteboard = DefaultPasteboard()

    @StateObject var settingsViewStore = SettingsViewStore(
        state: .init(keychain: keyChain),
        environment: .init(keychain: keyChain),
        reduceFunction: settingsReducer
    )
    @StateObject var linkViewStore = LinkViewStore(
        state: .init(),
        environment: .init(client: UniversalClient(keychain: keyChain)),
        reduceFunction: linkReducer
    )
    @StateObject var tagViewStore = TagViewStore(
        state: TagState(favoriteTags: UserDefaults.suite.favoriteTags),
        environment: TagEnvironment(
            client: UniversalClient(keychain: keyChain),
            userDefaults: .suite
        ),
        reduceFunction: tagReducer
    )
    @StateObject var appViewStore = AppViewStore(
        state: AppState(selectedListType: .all),
        environment: AppEnvironment(),
        reduceFunction: appReducer
    )

    var body: some Scene {
        WindowGroup {
            NavigationView {
                InitialContentView()
            }
            // TODO: add iOS only modifier
#if os(iOS)
            .introspectSplitViewController { splitViewController in
                splitViewController.preferredDisplayMode = .oneBesideSecondary
            }
#endif
            .environmentObject(settingsViewStore)
            .environmentObject(appViewStore)
            .environmentObject(tagViewStore)
            .environmentObject(linkViewStore)
        }
        //TODO: Refactor out creation of commands
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Link") {
                    appViewStore.send(.showAddView)
                }
                .keyboardShortcut("n", modifiers: [.command])
            }
            CommandGroup(after: .sidebar) {
                // TODO: Make title dynamic
                Button("Show Link Editor") {
                    if appViewStore.showLinkEditorSidebar {
                        appViewStore.send(.hideLinkEditorSidebar)
                    } else {
                        appViewStore.send(.showLinkEditorSidebar)
                    }
                }
                .keyboardShortcut("0", modifiers: [.command, .option])
                .disabled(appViewStore.selectedLinkID == nil)
            }
            CommandMenu("List") {
                Button("Refresh") {
                    if let linkType = appViewStore.selectedListType  {
                        linkViewStore.send(.load(linkType))
                    }
                    tagViewStore.send(.load)
                }
                .keyboardShortcut("R", modifiers: [.command])
                .disabled(appViewStore.selectedListType == nil)
            }
            CommandMenu("Link") {
                // TODO: Use same implementation as right click menu
                Button("Edit link") {
                    guard let selectedLinkID = appViewStore.selectedLinkID,
                          let selectedLink = linkViewStore.link(for: selectedLinkID) else {
                        return
                    }

                    appViewStore.send(.showEditLink(selectedLink))
                }
                .keyboardShortcut("e", modifiers: [.command])
                .disabled(appViewStore.selectedLinkID == nil)
                Button("Copy link to clipboard") {
                    guard let selectedLinkID = appViewStore.selectedLinkID,
                          let selectedLink = linkViewStore.link(for: selectedLinkID) else {
                        return
                    }

                    pasteboard.copyToPasteboard(string: selectedLink.url.absoluteString)
                }
                .keyboardShortcut("C", modifiers: [.command, .shift])
                .disabled(appViewStore.selectedLinkID == nil)
                Button("Delete") {
                    guard let selectedLinkID = appViewStore.selectedLinkID,
                          let selectedLink = linkViewStore.link(for: selectedLinkID) else {
                        return
                    }

                    // TODO: Clear selection after delete
                    linkViewStore.send(.delete(selectedLink))
                }
                .keyboardShortcut(.delete, modifiers: [.command])
                .disabled(appViewStore.selectedLinkID == nil)
            }
        }
        LinkAddScene(
            linkViewStore: linkViewStore,
            tagViewStore: tagViewStore,
            appViewStore: appViewStore
        ).handlesExternalEvents(matching: Set([WindowRoutes.addLink.rawValue]))
#if os(macOS)
        WindowGroup {
            SettingsView()
                .onDisappear {
                    appViewStore.send(.hideSettings)
                }
                .frame(width: 500, height: 300)
                .environmentObject(settingsViewStore)
        }
        .handlesExternalEvents(matching: Set([WindowRoutes.settings.rawValue]))
        Settings {
            SettingsView()
                .frame(width: 500, height: 300)
                .environmentObject(settingsViewStore)

        }
#endif
    }
}

struct LinkAddScene: Scene {
    @ObservedObject var linkViewStore: LinkViewStore
    @ObservedObject var tagViewStore: TagViewStore
    @ObservedObject var appViewStore: AppViewStore

    var body: some Scene {
        WindowGroup {
            LinkAddView().onDisappear {
                appViewStore.send(.hideAddView)
            }
            .environmentObject(linkViewStore)
            .environmentObject(tagViewStore)
        }
    }
}

enum WindowRoutes: String {
    case addLink
    case settings

#if os(macOS)
    func open() {
        if let url = URL(string: "aarle://\(self.rawValue)") {
            NSWorkspace.shared.open(url)
        }
    }
#endif
}
