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
    @Published var showsAddView = false
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
        // Use https://developer.apple.com/forums/thread/651592 to present add window only on macOS
//        WindowGroup {
//            LinkAddView(
//                linkStore: linkStore,
//                tagStore: tagStore
//            )
//        }
#if os(macOS)
        Settings {
            SettingsView()
        }
#endif
    }
}
