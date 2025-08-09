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
    self.settingsState = SettingsState(keychain: keychain)
    self.archiveState = ArchiveState(userDefaults: userDefaults)
    let listState = List.ListState(client: client)
    self.listState = listState

    self.addState = AddState()

    let navigationState = NavigationState()
    self.navigationState = navigationState

    self.editState = EditState(
      tagState: tagState,
      listState: listState,
      navigationState: navigationState
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

@Observable class AddState {
  var urlString: String = ""
  var title: String = ""
  var description: String = ""
  var tagsString: String = ""

  func reset() {
    urlString = ""
    title = ""
    description = ""
    tagsString = ""
  }
}

@Observable final class EditState {
  private let tagState: TagState
  private let listState: List.ListState
  private let navigationState: NavigationState

  private(set) var currentLink: Types.Link?

  var urlString: String = ""
  var title: String = ""
  var description: String = ""
  var tagsString: String = ""

  init(
    tagState: TagState,
    listState: List.ListState,
    navigationState: NavigationState
  ) {
    self.tagState = tagState
    self.listState = listState
    self.navigationState = navigationState
  }

  var favoriteTags: [Tag] { tagState.favoriteTags }

  func load(link: Types.Link) {
    currentLink = link
    urlString = link.url.absoluteString
    title = link.title ?? ""
    description = link.description ?? ""
    tagsString = link.tags.joined(separator: " ")
  }

  func reset() {
    currentLink = nil
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
    guard let currentLink else { return }
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
  }

  func closeEditUI() {
    navigationState.presentedEditLink = nil
    navigationState.showLinkEditorSidebar = false
  }
}
