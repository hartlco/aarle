//
//  InitialContentView.swift
//  Aarlo
//
//  Created by martinhartl on 12.01.22.
//

import SwiftUI

struct InitialContentView: View {
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    let linkStore = LinkStore(client: ShaarliClient())
    let tagStore = TagStore(client: ShaarliClient())
    // TODO: Make tagScope configurable
    let readLaterLinkStore = LinkStore(client: ShaarliClient(), tagScope: "toread")
    let webViewData = WebViewData(url: nil)

    @Binding var appState: AppState

    var body: some View {
        if compactEnvironment {
            SidebarView(linkStore: linkStore, tagStore: tagStore, appState: $appState)
                .navigationTitle("Aarlo")
        } else {
            SidebarView(linkStore: linkStore, tagStore: tagStore, appState: $appState)
                .navigationTitle("Aarlo")
            Text("No Sidebar Selection") // You won't see this in practice (default selection)
            WebView(data: webViewData)
        }
    }

    private var compactEnvironment: Bool {
        #if os(iOS)
        return horizontalSizeClass == .compact
        #elseif os(macOS)
        return false
        #else
        return false
        #endif
    }
}
