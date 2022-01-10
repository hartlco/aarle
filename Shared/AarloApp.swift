//
//  AarloApp.swift
//  Shared
//
//  Created by martinhartl on 02.01.22.
//

import SwiftUI

@main
struct AarloApp: App {
    let linkStore = LinkStore(client: ShaarliClient())
    // TODO: Make tagScope configurable
    let readLaterLinkStore = LinkStore(client: ShaarliClient(), tagScope: "toread")
    let webViewData = WebViewData(url: nil)
    let pasteboard = DefaultPasteboard()

    @State var selectedLink: Link?

    var body: some Scene {
        WindowGroup {
            NavigationView {
                SidebarView(linkStore: linkStore, readLaterLinkStore: readLaterLinkStore, selection: $selectedLink)
                Text("No Sidebar Selection") // You won't see this in practice (default selection)
                WebView(data: webViewData)
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
