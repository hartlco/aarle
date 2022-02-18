//
//  AarloApp.swift
//  Shared
//
//  Created by martinhartl on 02.01.22.
//

import SwiftUI
import SwiftUIX
import ViewStore

// TODO: Fix crash: Have 2 lists (Main, and tag). Modify link in tag view, go back to main. Crash
// Can be prevented if list has .id(UUID()) but this break pagination
@main
struct AarleApp: App {
    static let settingsStore = SettingsStore()

    let pasteboard = DefaultPasteboard()

    @StateObject var linkStore = LinkStore(client: UniversalClient(settingsStore: Self.settingsStore))

    @StateObject var tagViewStore = TagViewStore(
        state: TagState(favoriteTags: UserDefaults.suite.favoriteTags),
        environment: TagEnvironment(
            client: UniversalClient(settingsStore: Self.settingsStore),
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
            .environmentObject(Self.settingsStore)
            .environmentObject(appViewStore)
            .environmentObject(tagViewStore)
            .environmentObject(linkStore)
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
                        linkStore.reduce(.load(linkType))
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
                          let selectedLink = linkStore.link(for: selectedLinkID) else {
                        return
                    }

                    appViewStore.send(.showEditLink(selectedLink))
                }
                .keyboardShortcut("e", modifiers: [.command])
                .disabled(appViewStore.selectedLinkID == nil)
                Button("Copy link to clipboard") {
                    guard let selectedLinkID = appViewStore.selectedLinkID,
                          let selectedLink = linkStore.link(for: selectedLinkID) else {
                        return
                    }

                    pasteboard.copyToPasteboard(string: selectedLink.url.absoluteString)
                }
                .keyboardShortcut("C", modifiers: [.command, .shift])
                .disabled(appViewStore.selectedLinkID == nil)
                Button("Delete") {
                    guard let selectedLinkID = appViewStore.selectedLinkID,
                          let selectedLink = linkStore.link(for: selectedLinkID) else {
                        return
                    }

                    // TODO: Clear selection after delete
                    linkStore.reduce(.delete(selectedLink))
                }
                .keyboardShortcut(.delete, modifiers: [.command])
                .disabled(appViewStore.selectedLinkID == nil)
            }
        }
        LinkAddScene(
            linkStore: linkStore,
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
                .environmentObject(Self.settingsStore)
        }
        .handlesExternalEvents(matching: Set([WindowRoutes.settings.rawValue]))
        Settings {
            SettingsView()
                .frame(width: 500, height: 300)
                .environmentObject(Self.settingsStore)

        }
#endif
    }
}

struct LinkAddScene: Scene {
    @ObservedObject var linkStore: LinkStore
    @ObservedObject var tagViewStore: TagViewStore
    @ObservedObject var appViewStore: AppViewStore

    var body: some Scene {
        WindowGroup {
            LinkAddView().onDisappear {
                appViewStore.send(.hideAddView)
            }
            .environmentObject(linkStore)
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
