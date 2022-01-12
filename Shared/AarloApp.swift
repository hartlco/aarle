//
//  AarloApp.swift
//  Shared
//
//  Created by martinhartl on 02.01.22.
//

import SwiftUI

@main
struct AarloApp: App {
    let pasteboard = DefaultPasteboard()
    @State var selectedLink: Link?

    var body: some Scene {
        WindowGroup {
            NavigationView {
                InitialContentView(selectedLink: $selectedLink)
            }
            .tint(.tint)
        }
        .commands {
            CommandMenu("Link") {
                Button("Copy link to clipboard") {
                    guard let selectedLink = selectedLink else {
                        return
                    }

                    pasteboard.copyToPasteboard(string: selectedLink.url.absoluteString)
                }
                .keyboardShortcut("C", modifiers: [.command, .shift])
                .disabled(false)
            }
        }
    }
}
