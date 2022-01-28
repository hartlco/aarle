//
//  AarloApp.swift
//  Shared
//
//  Created by martinhartl on 02.01.22.
//

import SwiftUI
import SwiftUIX

// TODO: inject as env: https://www.hackingwithswift.com/quick-start/swiftui/how-to-use-environmentobject-to-share-data-between-views
final class AppState: ObservableObject {
    @Published var selectedLink: Link?
    @Published var showLinkEditorSidebar = false
    @Published var showsAddView = false {
        didSet {
#if os(macOS)
            // TODO: Introduce Reducer to handle changes/side-effect to the state
            if showsAddView == true {
                WindowRoutes.addLink.open()
            }
#endif
        }
    }
#if DEBUG
    static let stateMock = AppState()
#endif
}

@main
struct AarloApp: App {
    let pasteboard = DefaultPasteboard()
    @ObservedObject var appState = AppState()
    @StateObject var linkStore = LinkStore(client: ShaarliClient())
    @StateObject var tagStore = TagStore(client: ShaarliClient())

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            NavigationView {
                InitialContentView(linkStore: linkStore, tagStore: tagStore)
            }
            .environmentObject(appState)
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
                .disabled(appState.selectedLink == nil)
            }
            CommandMenu("Link") {
                Button("Copy link to clipboard") {
                    guard let selectedLink = appState.selectedLink else {
                        return
                    }

                    pasteboard.copyToPasteboard(string: selectedLink.url.absoluteString)
                }
                .keyboardShortcut("C", modifiers: [.command, .shift])
                .disabled(appState.selectedLink == nil)
            }
        }
        LinkAddScene(
            linkStore: linkStore,
            tagStore: tagStore,
            appState: appState
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
    @ObservedObject var appState: AppState

    var body: some Scene {
        WindowGroup {
            LinkAddView(
                linkStore: linkStore,
                tagStore: tagStore
            ).onDisappear {
                appState.showsAddView = false
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
