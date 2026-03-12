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
        Group {
            if overallAppState.useOfflineFallback {
                offlineList
            } else {
                onlineList
            }
        }
        .listStyle(PlainListStyle())
        .overlay {
            if overallAppState.isLoadingUnread && overallAppState.unreadLinks.isEmpty && archiveState.archiveLinks.isEmpty {
                VStack(spacing: 8) {
                    ProgressView()
                    Text("Loading unread...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .refreshable {
            await overallAppState.loadUnreadLinks()
        }
        .navigationTitle("Unread")
        .onAppear {
            if overallAppState.unreadLinks.isEmpty && !overallAppState.isLoadingUnread {
                overallAppState.refreshUnread()
            }
        }
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
        .sheet(item: $navigationState.presentedEditLink) { link in
            NavigationView {
                LinkEditView(
                    editState: overallAppState.editState,
                    showCancelButton: true
                )
                .onAppear {
                    overallAppState.editState.load(link: link)
                }
                .onDisappear {
                    overallAppState.editState.reset()
                }
                .navigationTitle("Edit Link")
            }
        }
    }

    // MARK: - Online list (API-fetched links as source of truth)

    private var onlineList: some View {
        List(
            overallAppState.unreadLinks,
            selection: $navigationState.selectedDetailDestination
        ) { link in
            NavigationLink(value: onlineDestination(for: link)) {
                HStack(spacing: 8) {
                    if showDownloadStatus {
                        onlineStatusIcon(for: link)
                    }
                    LinkItemView(link: link)
                }
            }
            .swipeActions(edge: .trailing) {
                Button {
                    Task {
                        await overallAppState.markLinkAsRead(link: link)
                    }
                } label: {
                    Label("Mark as Read", systemImage: "checkmark.circle")
                }
                .tint(.green)
            }
            .contextMenu {
                Button {
                    Task {
                        await overallAppState.markLinkAsRead(link: link)
                    }
                } label: {
                    Label("Mark as Read", systemImage: "checkmark.circle")
                }

                Button {
                    navigationState.presentedEditLink = link
                } label: {
                    Label("Edit", systemImage: "pencil")
                }

                if showDownloadStatus, let archiveLink = archiveLinkFor(link) {
                    if archiveLink.downloadFailed {
                        Button {
                            Task {
                                await archiveState.retryFailedDownload(archiveLink: archiveLink)
                            }
                        } label: {
                            Label("Retry Download", systemImage: "arrow.clockwise")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Offline fallback list (archived links)

    private var offlineList: some View {
        List(
            archiveState.archiveLinks,
            selection: $navigationState.selectedDetailDestination
        ) { link in
            NavigationLink(value: DetailNavigationDestination.archiveLink(link)) {
                HStack(spacing: 8) {
                    if showDownloadStatus {
                        offlineStatusIcon(for: link)
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
    }

    // MARK: - Helpers

    private func archiveLinkFor(_ link: Link) -> ArchiveLink? {
        archiveState.archiveLinks.first { $0.originalLinkId == link.id }
    }

    private func onlineDestination(for link: Link) -> DetailNavigationDestination {
        // If there's a successfully downloaded archive, navigate to it
        if showDownloadStatus,
           let archiveLink = archiveLinkFor(link),
           !archiveLink.downloadFailed {
            return .archiveLink(archiveLink)
        }
        // Otherwise navigate as a regular link (web view)
        return .link(link)
    }

    private func isPending(_ link: ArchiveLink) -> Bool {
        guard let originalId = link.originalLinkId else { return false }
        return archiveState.pendingDownloadIds.contains(originalId)
    }

    // MARK: - Status icons

    @ViewBuilder
    private func onlineStatusIcon(for link: Link) -> some View {
        if archiveState.pendingDownloadIds.contains(link.id) {
            ProgressView()
                .controlSize(.small)
        } else if let archiveLink = archiveLinkFor(link) {
            if archiveLink.downloadFailed {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.caption)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.caption)
            }
        } else {
            Image(systemName: "arrow.down.circle")
                .foregroundStyle(.secondary)
                .font(.caption)
        }
    }

    @ViewBuilder
    private func offlineStatusIcon(for link: ArchiveLink) -> some View {
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
}
