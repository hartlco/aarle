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
    var showDownloadStatus: Bool

    public init(
        archiveState: ArchiveState,
        navigationState: NavigationState,
        overallAppState: OverallAppState,
        showDownloadStatus: Bool
    ) {
        self.archiveState = archiveState
        self.navigationState = navigationState
        self.overallAppState = overallAppState
        self.showDownloadStatus = showDownloadStatus
    }

    var body: some View {
        List(
            archiveState.archiveLinks,
            selection: $navigationState.selectedDetailDestination
        ) { link in
            NavigationLink(value: destination(for: link)) {
                HStack(spacing: 8) {
                    if showDownloadStatus {
                        statusIcon(for: link)
                    }
                    LinkItemView(link: link)
                }
                .opacity(isPending(link) ? 0.5 : 1.0)
            }
            .disabled(isPending(link))
            .swipeActions(edge: .trailing) {
                Button {
                    Task {
                        await overallAppState.markAsRead(archiveLink: link)
                        navigationState.selectedDetailDestination = nil
                    }
                } label: {
                    Label("Mark as Read", systemImage: "checkmark.circle")
                }
                .tint(.green)
            }
            .swipeActions(edge: .leading) {
                if link.downloadFailed {
                    Button {
                        Task {
                            await archiveState.retryFailedDownload(archiveLink: link)
                        }
                    } label: {
                        Label("Retry", systemImage: "arrow.clockwise")
                    }
                    .tint(.blue)
                }
            }
            .contextMenu {
                if link.downloadFailed {
                    Button {
                        Task {
                            await archiveState.retryFailedDownload(archiveLink: link)
                        }
                    } label: {
                        Label("Retry Download", systemImage: "arrow.clockwise")
                    }
                }

                Button {
                    Task {
                        await overallAppState.markAsRead(archiveLink: link)
                        navigationState.selectedDetailDestination = nil
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
        .overlay {
            if archiveState.isSyncing && archiveState.archiveLinks.isEmpty {
                VStack(spacing: 8) {
                    ProgressView()
                    Text(archiveState.syncProgress)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .refreshable {
            overallAppState.syncUnreadIfEnabled()
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

    private func isPending(_ link: ArchiveLink) -> Bool {
        guard let originalId = link.originalLinkId else { return false }
        return archiveState.pendingDownloadIds.contains(originalId)
    }

    @ViewBuilder
    private func statusIcon(for link: ArchiveLink) -> some View {
        if isPending(link) {
            ProgressView()
                .controlSize(.small)
        } else if link.downloadFailed {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.caption)
        } else {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.caption)
        }
    }

    private func destination(for link: ArchiveLink) -> DetailNavigationDestination {
        // Always navigate as archiveLink so toolbar actions (edit, mark as read) work correctly.
        // For failed downloads, InitialContentView handles the fallback to web view.
        return .archiveLink(link)
    }
}
