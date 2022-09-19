//
//  DownloadedListView.swift
//  Aarle
//
//  Created by Martin Hartl on 18.04.22.
//

import SwiftUI
import Types
import Archive

struct DownloadedListView: View {
    @ObservedObject var archiveState: ArchiveState
    @Binding var selectedArchiveLink: ArchiveLink?
    
    public init(
        archiveState: ArchiveState,
        selectedArchiveLink: Binding<ArchiveLink?>
    ) {
        self.archiveState = archiveState
        self._selectedArchiveLink = selectedArchiveLink
    }

    var body: some View {
        List(
            archiveState.archiveLinks,
            selection: $selectedArchiveLink
        ) { link in
            NavigationLink(value: link) {
                LinkItemView(link: link)
            }
        }
        .navigationDestination(for: ArchiveLink.self) { link in
            DataWebView(archiveLink: link)
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
