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

    var body: some Scene {
        WindowGroup {
            NavigationView {
                SidebarView(linkStore: linkStore, readLaterLinkStore: readLaterLinkStore)
                Text("No Sidebar Selection") // You won't see this in practice (default selection)
                WebView(data: webViewData)
            }
        }
    }
}
