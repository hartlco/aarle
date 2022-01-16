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
    @ObservedObject var tagStore: TagStore

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
                        destination: TagListView(tagStore: tagStore)
                    ) {
                        Label("Tags", systemImage: "tag")
                    }
                }
                Section(header: "Favorites") {
                    ForEach(tagStore.favoriteTags) { tag in
                        NavigationLink(
                            destination: ContentView(title: tag.name, linkStore: LinkStore(client: ShaarliClient(), tagScope: tag.name), linkSelection: $selection)
                        ) {
                            Label(tag.name, systemImage: "tag")
                        }
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
            tagStore: TagStore.mock,
            selection: State<Link?>(initialValue: nil).projectedValue
        )
    }
}
#endif
