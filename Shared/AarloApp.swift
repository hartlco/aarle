//
//  AarloApp.swift
//  Shared
//
//  Created by martinhartl on 02.01.22.
//

import KeychainAccess
import SwiftUI
import Settings
import Types
import List
import Navigation

@main
struct AarleApp: App {
  static let keyChain = Keychain(service: "co.hartl.Aarle")

  let pasteboard = DefaultPasteboard()
  @Environment(\.scenePhase) private var scenePhase

  @State var overallAppState = OverallAppState(
    client: UniversalClient(keychain: keyChain),
    keychain: keyChain
  )

  var body: some Scene {
    WindowGroup {
      InitialContentView()
        .environment(overallAppState)
        .onAppear {
          Task {
            await overallAppState.flushPendingMarkAsRead()
          }
          overallAppState.refreshUnread()
        }
        .onChange(of: scenePhase) { _, newPhase in
          if newPhase == .active {
            Task {
              await overallAppState.flushPendingMarkAsRead()
            }
            overallAppState.refreshUnread()
          }
        }
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
          overallAppState.archiveState.refresh()
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
      SettingsView(
        settingsState: overallAppState.settingsState,
        syncStatus: overallAppState.unreadSyncStatus,
        onClearAllDownloads: {
          overallAppState.archiveState.clearAllArchives()
        },
        onRetryAllFailed: {
          await overallAppState.archiveState.retryAllFailed()
        }
      )
        .onDisappear {
          overallAppState.navigationState.showsSettings = false
        }
        .frame(width: 500, height: 400)
    }
    .handlesExternalEvents(matching: Set([WindowRoutes.settings.rawValue]))
    Settings {
      SettingsView(
        settingsState: overallAppState.settingsState,
        syncStatus: overallAppState.unreadSyncStatus,
        onClearAllDownloads: {
          overallAppState.archiveState.clearAllArchives()
        },
        onRetryAllFailed: {
          await overallAppState.archiveState.retryAllFailed()
        }
      )
        .frame(width: 500, height: 400)
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
          editState: overallAppState.editState,
          showCancelButton: false
        ).onAppear {
          overallAppState.editState.load(link: presentedEditLink)
        }
        .onDisappear {
          navigationState.showsAddView = false
        }
      } else {
        Text("Edit Link 2")
      }
    }
  }
}
