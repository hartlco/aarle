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

  init(
    client: BookmarkClient,
    userDefaults: UserDefaults = .suite,
    keychain: AarleKeychain
  ) {
    self.client = client
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
  }

  var navigationState: NavigationState
  var tagState: TagState
  var settingsState: SettingsState
  var archiveState: ArchiveState
  var listState: List.ListState
  var addState: AddState
  var editState: EditState
}

@MainActor
@Observable class AddState {
  var urlString: String = ""
  var title: String = ""
  var description: String = ""
  var tagsString: String = ""
  var shouldArchive: Bool = false
  var isLoadingMetadata: Bool = false
  var isSaving: Bool = false
  var onSaveComplete: (() -> Void)?

  func reset() {
    urlString = ""
    title = ""
    description = ""
    tagsString = ""
    shouldArchive = false
    isLoadingMetadata = false
    isSaving = false
    onSaveComplete = nil
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

  func load(link: Types.Link) {
    currentLink = link
    currentArchiveLink = nil
    urlString = link.url.absoluteString
    title = link.title ?? ""
    description = link.description ?? ""
    tagsString = link.tags.joined(separator: " ")
  }

  func load(archiveLink: ArchiveLink) {
    currentArchiveLink = archiveLink
    currentLink = nil
    urlString = archiveLink.url.absoluteString
    title = archiveLink.title ?? ""
    description = archiveLink.description ?? ""
    tagsString = archiveLink.tags.joined(separator: " ")
  }

  func reset() {
    currentLink = nil
    currentArchiveLink = nil
    urlString = ""
    title = ""
    description = ""
    tagsString = ""
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
        created: currentLink.created
      )
      await listState.update(link: newLink)
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

  func closeEditUI() {
    navigationState.presentedEditLink = nil
    navigationState.presentedEditArchiveLink = nil
    navigationState.showLinkEditorSidebar = false
  }
}
