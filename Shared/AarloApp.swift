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
            .environmentObject(Self.settingsStore)
            .environmentObject(appStore)
            .environmentObject(tagStore)
            .environmentObject(linkStore)
            .tint(.tint)
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
            CommandMenu("Link") {
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
                .environmentObject(Self.settingsStore)
        }
        .handlesExternalEvents(matching: Set([WindowRoutes.settings.rawValue]))
        Settings {
            SettingsView()
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
