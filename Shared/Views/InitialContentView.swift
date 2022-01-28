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

    // TODO: Inject them from the AppState
    @ObservedObject var linkStore: LinkStore
    @EnvironmentObject var tagStore: TagStore
    
    // TODO: Make tagScope configurable
    let readLaterLinkStore = LinkStore(client: ShaarliClient(), tagScope: "toread")
    let webViewData = WebViewData(url: nil)

    var body: some View {
        if compactEnvironment {
            SidebarView(
                isDefaultItemActive: false,
                linkStore: linkStore
            ).navigationTitle("aarle")
        } else {
            SidebarView(linkStore: linkStore)
                .navigationTitle("aarle")
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
