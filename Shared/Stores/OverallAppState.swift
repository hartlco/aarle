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
    self.tagState = TagState(
      client: client,
      userDefaults: userDefaults,
      favoriteTags: userDefaults.favoriteTags
    )
    self.settingsState = SettingsState(keychain: keychain)
    self.archiveState = ArchiveState(userDefaults: userDefaults)
    self.listState = List.ListState(client: client)
    self.addState = AddState()
  }

  var navigationState: NavigationState = .init()
  var tagState: TagState
  var settingsState: SettingsState
  var archiveState: ArchiveState
  var listState: List.ListState
  var addState: AddState
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
