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
                Section(header: "Links") {
                    NavigationLink(
                        destination: ContentView(title: "Links", linkStore: linkStore, linkSelection: $selection),
                        isActive: $isDefaultItemActive
                    ) {
                        Label("All", systemImage: "tray.2")
                    }
                    NavigationLink(
                        destination: ContentView(title: "Read Later", linkStore: readLaterLinkStore, linkSelection: $selection)
                    ) {
                        Label("Read Later", systemImage: "paperplane")
                    }
                    NavigationLink(
                        destination: TagListView(linkStore: linkStore)
                    ) {
                        Label("Tags", systemImage: "tag")
                    }
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
