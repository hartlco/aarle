//
//  DownloadedListView.swift
//  Aarle
//
//  Created by Martin Hartl on 18.04.22.
//

import SwiftUI
import Types
import Archive
import Navigation

struct DownloadedListView: View {
    @Bindable var archiveState: ArchiveState
    @Bindable var navigationState: NavigationState

    public init(
        archiveState: ArchiveState,
        navigationState: NavigationState
    ) {
        self.archiveState = archiveState
        self.navigationState = navigationState
    }

    var body: some View {
        List(
            archiveState.archiveLinks,
            selection: $navigationState.selectedDetailDestination
        ) { link in
            NavigationLink(value: DetailNavigationDestination.archiveLink(link)) {
                LinkItemView(link: link)
            }
            .contextMenu {
                Button(role: .destructive) {
                    do {
                        try archiveState.deleteLink(link: link)
                        navigationState.selectedDetailDestination = .empty
                    } catch {
                        // TODO: Error Handling
                    }
                } label: {
                    Label("Delete Download", systemImage: "trash")
                }
            }
        }
        .listStyle(PlainListStyle())
        .navigationTitle("Download")
        .toolbar {
            ToolbarItem {
                Button {
                    // TODO: Show add screen
                } label: {
                    Label("Add", systemImage: "plus")
                }
                #if os(iOS)
//                .sheet(
//                    isPresented: appViewStore.binding(
//                        get: \.showsAddView,
//                        send: { .setShowAddView($0) }
//                    ),
//                    onDismiss: nil,
//                    content: {
//                        LinkAddView()
//                    }
//                )
                #endif
            }
        }
    }
}
