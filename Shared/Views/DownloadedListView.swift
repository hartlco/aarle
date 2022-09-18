//
//  DownloadedListView.swift
//  Aarle
//
//  Created by Martin Hartl on 18.04.22.
//

import SwiftUI
import Types

struct DownloadedListView: View {
    @ObservedObject var overallAppState: OverallAppState

    var body: some View {
        List(
            overallAppState.archiveState.archiveLinks,
            selection: $overallAppState.selectedArchiveLink
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
