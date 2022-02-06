//
//  AarloApp.swift
//  Shared
//
//  Created by martinhartl on 02.01.22.
//

import SwiftUI
import SwiftUIX

@main
struct AarleApp: App {
    static let settingsStore = SettingsStore()

    let pasteboard = DefaultPasteboard()
    @StateObject var appStore = AppStore()
    @StateObject var linkStore = LinkStore(client: UniversalClient(settingsStore: Self.settingsStore))
    @StateObject var tagStore = TagStore(client: UniversalClient(settingsStore: Self.settingsStore))

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
            .environmentObject(appStore)
            .environmentObject(tagStore)
            .environmentObject(linkStore)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Link") {
                    appStore.reduce(.showAddView)
                }
                .keyboardShortcut("n", modifiers: [.command])
            }
            CommandGroup(after: .sidebar) {
                // TODO: Make title dynamic
                Button("Show Link Editor") {
                    if appStore.showLinkEditorSidebar {
                        appStore.reduce(.hideLinkEditorSidebar)
                    } else {
                        appStore.reduce(.showLinkEditorSidebar)
                    }
                }
                .keyboardShortcut("0", modifiers: [.command, .option])
                .disabled(appStore.selectedLink.wrappedValue == nil)
            }
            CommandMenu("List") {
                Button("Refresh") {
                    if let linkType = appStore.selectedListType.wrappedValue  {
                        linkStore.reduce(.load(linkType))
                    }
                    tagStore.reduce(.load)
                }
                .keyboardShortcut("R", modifiers: [.command])
                .disabled(appStore.selectedLink.wrappedValue == nil)
            }
            CommandMenu("Link") {
                // TODO: Use same implementation as right click menu
                Button("Edit link") {
                    guard let selectedLink = appStore.selectedLink.wrappedValue else {
                        return
                    }

                    appStore.reduce(.showEditLink(selectedLink))
                }
                .keyboardShortcut("e", modifiers: [.command])
                .disabled(appStore.selectedLink.wrappedValue == nil)
                Button("Copy link to clipboard") {
                    guard let selectedLink = appStore.selectedLink.wrappedValue else {
                        return
                    }

                    pasteboard.copyToPasteboard(string: selectedLink.url.absoluteString)
                }
                .keyboardShortcut("C", modifiers: [.command, .shift])
                .disabled(appStore.selectedLink.wrappedValue == nil)
            }
        }
        LinkAddScene(
            linkStore: linkStore,
            tagStore: tagStore,
            appStore: appStore
        ).handlesExternalEvents(matching: Set([WindowRoutes.addLink.rawValue]))
#if os(macOS)
        WindowGroup {
            SettingsView()
                .onDisappear {
                    appStore.reduce(.hideSettings)
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
    @ObservedObject var tagStore: TagStore
    @ObservedObject var appStore: AppStore

    var body: some Scene {
        WindowGroup {
            LinkAddView().onDisappear {
                appStore.reduce(.hideAddView)
            }
            .environmentObject(tagStore)
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
