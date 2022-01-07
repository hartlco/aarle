//
//  SidebarView.swift
//  Aarlo
//
//  Created by martinhartl on 07.01.22.
//

import SwiftUI
import SwiftUIX

struct SidebarView: View {
    @State private var isDefaultItemActive = true

    @ObservedObject var linkStore: LinkStore
    @ObservedObject var readLaterLinkStore: LinkStore
    @ObservedObject var webViewData: WebViewData

    var body: some View {
        List {
            Text("Links")
                .font(.caption)
                .foregroundColor(.secondary)
            NavigationLink(destination: ContentView(linkStore: linkStore, webViewData: webViewData), isActive: $isDefaultItemActive) {
                Label("All", systemImage: "tray.2")
            }
            NavigationLink(destination: ContentView(linkStore: readLaterLinkStore, webViewData: webViewData)) {
                Label("Read Later", systemImage: "paperplane")
            }
        }.listStyle(SidebarListStyle())
    }
}

//struct SidebarView_Previews: PreviewProvider {
//    static var previews: some View {
//        SidebarView()
//    }
//}
