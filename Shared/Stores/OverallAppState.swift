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

// TODO: Adopt @Observable
@MainActor
final class OverallAppState: ObservableObject {
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
    }

    @Published var navigationState: NavigationState = .init()
    @Published var tagState: TagState
    @Published var settingsState: SettingsState
    @Published var archiveState: ArchiveState
    @Published var listState: List.ListState
}
