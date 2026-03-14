//
//  OverallAppState.swift
//  Aarle
//
//  Created by Martin Hartl on 01.09.22.
//

import Foundation
import Types
import AarleKeychain
import Settings
import Archive
import Navigation
import List
import Tag
import Observation

@MainActor
@Observable
final class OverallAppState {
  let client: BookmarkClient
  let universalClient: UniversalClient?

  init(
    client: BookmarkClient,
    userDefaults: UserDefaults = .suite,
    keychain: AarleKeychain
  ) {
    self.client = client
    self.universalClient = client as? UniversalClient
    let tagState = TagState(
      client: client,
      userDefaults: userDefaults,
      favoriteTags: userDefaults.favoriteTags
    )
    self.tagState = tagState
    let settingsState = SettingsState(keychain: keychain)
    self.settingsState = settingsState
    let archiveState = ArchiveState(
      userDefaults: userDefaults,
      metadataEndpointProvider: { settingsState.metadataEndpoint }
    )
    self.archiveState = archiveState
    let listState = List.ListState(client: client)
    self.listState = listState

    self.addState = AddState()

    let navigationState = NavigationState()
    self.navigationState = navigationState

    self.editState = EditState(
      tagState: tagState,
      listState: listState,
      navigationState: navigationState,
      archiveState: archiveState
    )

    settingsState.onAutoSyncChanged = { [weak archiveState] in
      archiveState?.clearAllArchives()
    }

    self.editState.onMarkAsRead = { [weak self] archiveLink in
      await self?.markAsRead(archiveLink: archiveLink)
    }

    self.editState.onToggleUnread = { [weak self] link, unread in
      if unread {
        await self?.markLinkAsUnread(link: link)
      } else {
        await self?.markLinkAsRead(link: link)
      }
    }
  }

  var navigationState: NavigationState
  var tagState: TagState
  var settingsState: SettingsState
  var archiveState: ArchiveState
  var listState: List.ListState
  var addState: AddState
  var editState: EditState

  var unreadLinks: [Link] = []
  var isLoadingUnread = false
  var useOfflineFallback = false

  private var syncTask: Task<Void, Never>?

  func loadUnreadLinks() async {
    guard let universalClient else { return }
    guard !isLoadingUnread else { return }

    isLoadingUnread = true
    do {
      let links = try await universalClient.loadUnread()
      unreadLinks = links
      useOfflineFallback = false
      isLoadingUnread = false

      // If auto-sync is enabled, also trigger download sync
      if settingsState.autoSyncUnread {
        await archiveState.syncUnreadBookmarks(unreadLinks: links)
      }
    } catch {
      // API failed — fall back to offline archive if available
      if !archiveState.archiveLinks.isEmpty {
        useOfflineFallback = true
      }
      isLoadingUnread = false
    }
  }

  func refreshUnread() {
    syncTask?.cancel()
    syncTask = Task {
      await loadUnreadLinks()
    }
  }

  func markAsRead(archiveLink: ArchiveLink) async {
    guard let originalLinkId = archiveLink.originalLinkId,
          let universalClient else { return }

    // Optimistic: remove locally immediately
    unreadLinks.removeAll { $0.id == originalLinkId }
    try? archiveState.deleteLink(link: archiveLink)

    do {
      try await universalClient.markAsRead(linkId: originalLinkId)
    } catch {
      // Queue for later sync when back online
      archiveState.queuePendingMarkAsRead(linkId: originalLinkId)
    }
  }

  func markLinkAsRead(link: Link) async {
    guard let universalClient else { return }

    // Optimistic: remove from unread list and matching archive link locally
    unreadLinks.removeAll { $0.id == link.id }
    if let archiveLink = archiveState.archiveLinks.first(where: { $0.originalLinkId == link.id }) {
      try? archiveState.deleteLink(link: archiveLink)
    }

    do {
      try await universalClient.markAsRead(linkId: link.id)
    } catch {
      // Queue for later sync when back online
      archiveState.queuePendingMarkAsRead(linkId: link.id)
    }
  }

  func flushPendingMarkAsRead() async {
    guard let universalClient else { return }
    let pendingIds = archiveState.dequeuePendingMarkAsReadIds()
    guard !pendingIds.isEmpty else { return }

    var failedIds: [String] = []
    for id in pendingIds {
      do {
        try await universalClient.markAsRead(linkId: id)
      } catch {
        failedIds.append(id)
      }
    }

    // Re-queue any that still failed
    for id in failedIds {
      archiveState.queuePendingMarkAsRead(linkId: id)
    }
  }

  func markLinkAsUnread(link: Link) async {
    guard let universalClient else { return }
    do {
      try await universalClient.markAsUnread(linkId: link.id)
      refreshUnread()
    } catch {
      // Mark-as-unread errors are non-fatal
    }
  }


  var unreadSyncStatus: UnreadSyncStatus {
    UnreadSyncStatus(
      isSyncing: archiveState.isSyncing,
      syncProgress: archiveState.syncProgress,
      totalCount: archiveState.archiveLinks.count,
      downloadedCount: archiveState.downloadedCount,
      failedCount: archiveState.failedCount,
      pendingCount: archiveState.pendingDownloadIds.count
    )
  }
}

enum ServiceReachability: Equatable {
  case unknown
  case checking
  case reachable
  case unreachable
}

@MainActor
@Observable class AddState {
  var urlString: String = ""
  var title: String = ""
  var description: String = ""
  var tagsString: String = ""
  var shouldArchive: Bool = false
  var markAsUnread: Bool = false
  var isLoadingMetadata: Bool = false
  var isSaving: Bool = false
  var onSaveComplete: (() -> Void)?
  var linkdingReachability: ServiceReachability = .unknown
  var metadataReachability: ServiceReachability = .unknown

  func reset() {
    urlString = ""
    title = ""
    description = ""
    tagsString = ""
    shouldArchive = false
    markAsUnread = false
    isLoadingMetadata = false
    isSaving = false
    onSaveComplete = nil
    linkdingReachability = .unknown
    metadataReachability = .unknown
  }
}

@MainActor
@Observable final class EditState {
  private let tagState: TagState
  private let listState: List.ListState
  private let navigationState: NavigationState
  private let archiveState: ArchiveState

  private(set) var currentLink: Types.Link?
  private(set) var currentArchiveLink: ArchiveLink?

  var urlString: String = ""
  var title: String = ""
  var description: String = ""
  var tagsString: String = ""
  var unread: Bool = false

  var onMarkAsRead: ((ArchiveLink) async -> Void)?
  var onToggleUnread: ((Types.Link, Bool) async -> Void)?

  var isEditingArchiveLink: Bool { currentArchiveLink != nil }

  init(
    tagState: TagState,
    listState: List.ListState,
    navigationState: NavigationState,
    archiveState: ArchiveState
  ) {
    self.tagState = tagState
    self.listState = listState
    self.navigationState = navigationState
    self.archiveState = archiveState
  }

  var favoriteTags: [Tag] { tagState.favoriteTags }
  var allTags: [Tag] { tagState.tags }

  func load(link: Types.Link) {
    currentLink = link
    currentArchiveLink = nil
    urlString = link.url.absoluteString
    title = link.title ?? ""
    description = link.description ?? ""
    tagsString = link.tags.joined(separator: " ")
    unread = link.unread
  }

  func load(archiveLink: ArchiveLink) {
    currentArchiveLink = archiveLink
    currentLink = nil
    urlString = archiveLink.url.absoluteString
    title = archiveLink.title ?? ""
    description = archiveLink.description ?? ""
    tagsString = archiveLink.tags.joined(separator: " ")
    unread = false
  }

  func reset() {
    currentLink = nil
    currentArchiveLink = nil
    urlString = ""
    title = ""
    description = ""
    tagsString = ""
    unread = false
  }

  func tagsStringContains(_ tag: Tag) -> Bool {
    tagState.tagsString(tagsString, contains: tag)
  }

  func appendTag(_ tag: Tag) {
    tagsString = tagState.addingTag(tag, toTagsString: tagsString)
  }

  func removeTag(_ tag: Tag) {
    tagsString = tagState.removingTag(tag, fromTagsString: tagsString)
  }

  func save() async {
    if let currentLink = currentLink {
      // Save regular link
      let url = URL(string: urlString) ?? currentLink.url
      let tags = tagsString.components(separatedBy: " ")
      let newLink = Types.Link(
        id: currentLink.id,
        url: url,
        title: title,
        description: description,
        tags: tags,
        private: false,
        created: currentLink.created,
        unread: unread
      )
      await listState.update(link: newLink)
      // If unread status changed, toggle via API
      if unread != currentLink.unread {
        await onToggleUnread?(newLink, unread)
      }
    } else if let currentArchiveLink = currentArchiveLink {
      // Save archive link and sync to original if it exists
      let url = URL(string: urlString) ?? currentArchiveLink.url
      let tags = tagsString.components(separatedBy: " ")
      let updatedArchiveLink = ArchiveLink(
        id: currentArchiveLink.id,
        originalLinkId: currentArchiveLink.originalLinkId,
        title: title,
        description: description,
        content: currentArchiveLink.content,
        dataURL: currentArchiveLink.dataURL,
        tags: tags,
        url: url
      )
      
      // Update the archive link in local storage
      await archiveState.updateLink(link: updatedArchiveLink)
      
      // If there's an originalLinkId, sync changes back to the original link
      if let originalLinkId = currentArchiveLink.originalLinkId,
         let originalLink = listState.link(for: originalLinkId) {
        let syncedLink = Types.Link(
          id: originalLink.id,
          url: url,
          title: title,
          description: description,
          tags: tags,
          private: originalLink.private,
          created: originalLink.created
        )
        await listState.update(link: syncedLink)
      }
    }
  }

  func markCurrentAsRead() async {
    guard let archiveLink = currentArchiveLink else { return }
    await onMarkAsRead?(archiveLink)
    closeEditUI()
  }

  func closeEditUI() {
    navigationState.presentedEditLink = nil
    navigationState.presentedEditArchiveLink = nil
    navigationState.showLinkEditorSidebar = false
  }
}
