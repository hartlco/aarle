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
    var overallAppState: OverallAppState

    public init(
        archiveState: ArchiveState,
        navigationState: NavigationState,
        overallAppState: OverallAppState
    ) {
        self.archiveState = archiveState
        self.navigationState = navigationState
        self.overallAppState = overallAppState
    }

    var body: some View {
        ZStack {
            List(
                archiveState.archiveLinks,
                selection: $navigationState.selectedDetailDestination
            ) { link in
                NavigationLink(value: destination(for: link)) {
                    HStack {
                        LinkItemView(link: link)
                        if link.downloadFailed {
                            Spacer()
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                                .font(.caption)
                        }
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button {
                        Task {
                            await overallAppState.markAsRead(archiveLink: link)
                            navigationState.selectedDetailDestination = .empty
                        }
                    } label: {
                        Label("Mark as Read", systemImage: "checkmark.circle")
                    }
                    .tint(.green)
                }
                .contextMenu {
                    Button {
                        Task {
                            await overallAppState.markAsRead(archiveLink: link)
                            navigationState.selectedDetailDestination = .empty
                        }
                    } label: {
                        Label("Mark as Read", systemImage: "checkmark.circle")
                    }

                    Button {
                        navigationState.presentedEditArchiveLink = link
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                }
            }
            .listStyle(PlainListStyle())
            if archiveState.isSyncing {
                VStack {
                    ProgressView()
                        .padding()
                    Spacer()
                }
            }
        }
        .refreshable {
            await overallAppState.syncUnreadIfEnabled()
        }
        .task {
            await overallAppState.syncUnreadIfEnabled()
        }
        .navigationTitle("Unread")
        .sheet(item: $navigationState.presentedEditArchiveLink) { archiveLink in
            NavigationView {
                LinkEditView(
                    editState: overallAppState.editState,
                    showCancelButton: true
                )
                .onAppear {
                    overallAppState.editState.load(archiveLink: archiveLink)
                }
                .onDisappear {
                    overallAppState.editState.reset()
                }
                .navigationTitle("Edit Archive")
            }
        }
    }

    private func destination(for link: ArchiveLink) -> DetailNavigationDestination {
        if link.downloadFailed {
            // Fall back to web view for failed downloads
            let webLink = Link(
                id: link.originalLinkId ?? link.id,
                url: link.url,
                title: link.title,
                description: link.description,
                tags: link.tags,
                private: false,
                created: Date()
            )
            return .link(webLink)
        }
        return .archiveLink(link)
    }
}
