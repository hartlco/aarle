//
//  InitialContentView.swift
//  Aarlo
//
//  Created by martinhartl on 12.01.22.
//

import SwiftUI
import Introspect

struct InitialContentView: View {    
    @EnvironmentObject var linkViewStore: LinkViewStore
    @EnvironmentObject var tagViewStore: TagViewStore
    
    let webViewData = WebViewData(url: nil)
    
    var body: some View {
#if os(iOS)
        sidebar
#else
        sidebar
        Text("No Sidebar Selection") // You won't see this in practice (default selection)
        WebView(data: webViewData)
#endif
    }
    
    private var sidebar: some View {
        SidebarView()
            .navigationTitle("aarle")
            .alert(isPresented: linkViewStore.binding(get: \.showLoadingError, send: { .setShowLoadingError($0 )})) {
                networkingAlert
            }
            .alert(isPresented: tagViewStore.binding(
                get: \.showLoadingError, send: { .setShowLoadingError($0) })
            ) {
                networkingAlert
            }
    }
    
    private var networkingAlert: Alert {
        Alert(
            title: Text("Networking Error"),
            message: Text("Please try again.")
        )
    }
}
