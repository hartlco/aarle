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

    @EnvironmentObject var linkStore: LinkStore
    @EnvironmentObject var tagStore: TagStore
    
    let webViewData = WebViewData(url: nil)

    var body: some View {
        if compactEnvironment {
            SidebarView()
                .navigationTitle("aarle")
                .alert(isPresented: linkStore.showLoadingError) {
                    networkingAlert
                }
                .alert(isPresented: tagStore.showLoadingError) {
                    networkingAlert
                }
        } else {
            SidebarView()
                .navigationTitle("aarle")
                .alert(isPresented: linkStore.showLoadingError) {
                    networkingAlert
                }
                .alert(isPresented: tagStore.showLoadingError) {
                    networkingAlert
                }
            Text("No Sidebar Selection") // You won't see this in practice (default selection)
            WebView(data: webViewData)
        }
    }

    private var networkingAlert: Alert {
        Alert(
            title: Text("Networking Error"),
            message: Text("Please try again.")
        )
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
