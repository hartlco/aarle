//
//  AarloApp.swift
//  Shared
//
//  Created by martinhartl on 02.01.22.
//

import SwiftUI
import SwiftUIX

@main
struct AarloApp: App {
    let pasteboard = DefaultPasteboard()
    @ObservedObject var appStore = AppStore()
    @StateObject var linkStore = LinkStore(client: ShaarliClient())
    @StateObject var tagStore = TagStore(client: ShaarliClient())

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            NavigationView {
                InitialContentView(linkStore: linkStore, tagStore: tagStore)
            }
            .environmentObject(appStore)
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
        Settings {
            SettingsView()
        }
#endif
    }
}

struct LinkAddScene: Scene {
    @Environment(\.scenePhase) private var scenePhase

    @ObservedObject var linkStore: LinkStore
    @ObservedObject var tagStore: TagStore
    @ObservedObject var appStore: AppStore

    var body: some Scene {
        WindowGroup {
            LinkAddView(
                linkStore: linkStore,
                tagStore: tagStore
            ).onDisappear {
                appStore.reduce(.hideAddView)
            }
        }
    }
}

enum WindowRoutes: String {
    case addLink

    #if os(macOS)
    func open() {
        if let url = URL(string: "aarle://\(self.rawValue)") {
            NSWorkspace.shared.open(url)
        }
    }
    #endif
}
