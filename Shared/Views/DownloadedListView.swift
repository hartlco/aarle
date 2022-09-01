//
//  DownloadedListView.swift
//  Aarle
//
//  Created by Martin Hartl on 18.04.22.
//

import SwiftUI
import Types

struct DownloadedListView: View {
    @EnvironmentObject var archiveViewStore: ArchiveViewStore
    @EnvironmentObject var overallAppState: OverallAppState

    var body: some View {
        List(
            archiveViewStore.archiveLinks,
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

struct DownloadedListView_Previews: PreviewProvider {
    static var previews: some View {
        DownloadedListView()
    }
}
