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

    @Binding var selection: Link?

    var body: some View {
        ZStack {
            List {
                Text("Links")
                    .font(.caption)
                    .foregroundColor(.secondary)
                NavigationLink(
                    destination: ContentView(linkStore: linkStore, linkSelection: $selection),
                    isActive: $isDefaultItemActive
                ) {
                    Label("All", systemImage: "tray.2")
                }
                NavigationLink(
                    destination: ContentView(linkStore: readLaterLinkStore, linkSelection: $selection)
                ) {
                    Label("Read Later", systemImage: "paperplane")
                }
            }.listStyle(SidebarListStyle())
        }
    }
}

#if DEBUG
struct SidebarView_Previews: PreviewProvider {
    static var previews: some View {
        SidebarView(
            linkStore: LinkStore.mock,
            readLaterLinkStore: LinkStore.mock,
            selection: State<Link?>(initialValue: nil).projectedValue
        )
    }
}
#endif
