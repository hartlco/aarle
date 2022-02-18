//
//  AppStore.swift
//  Aarlo
//
//  Created by martinhartl on 28.01.22.
//

import Foundation
import SwiftUI
import ViewStore

typealias AppViewStore = ViewStore<AppState, AppAction, AppEnvironment>

struct AppState {
    var selectedListType: ListType?
    var selectedLinkID: String?
    var presentedEditLink: Link?
    var showLinkEditorSidebar = false
    var showsAddView = false
    var showsSettings = false
}

enum AppAction {
    case setSelectedLinkID(String?)
    case setSelectedListType(ListType?)
    case setShowLinkEditorSidebar(Bool)
    case showLinkEditorSidebar
    case hideLinkEditorSidebar

    case setEditLink(Link?)
    case showEditLink(Link)
    case hideEditLink

    case setShowAddView(Bool)
    case showAddView
    case hideAddView
    case setShowSettings(Bool)
    case showSettings
    case hideSettings
}

let appReducer: ReduceFunction<AppState, AppAction, AppEnvironment> = { state, action, environment in
    switch action {
    case let .setSelectedLinkID(id):
        state.selectedLinkID = id
    case let .setSelectedListType(type):
        state.selectedListType = type
    case .showLinkEditorSidebar:
        state.showLinkEditorSidebar = true
    case .hideLinkEditorSidebar:
        state.showLinkEditorSidebar = false
    case let .setShowLinkEditorSidebar(value):
        state.showLinkEditorSidebar = value
    case let .setShowAddView(value):
        state.showsAddView = true
    case .showAddView:
        state.showsAddView = true
#if os(macOS)
        // TODO: Move into side-effect
        WindowRoutes.addLink.open()
#endif
    case .hideAddView:
        state.showsAddView = false
    case .showSettings:
        state.showsSettings = true

#if os(macOS)
        // TODO: Move into side-effect
        WindowRoutes.settings.open()
#endif
    case let .setShowSettings(value):
        state.showsSettings = value
    case .hideSettings:
        state.showsSettings = false
    case let .setEditLink(link):
        state.presentedEditLink = link
    case let .showEditLink(link):
        state.presentedEditLink = link
    case .hideEditLink:
        state.presentedEditLink = nil
    }
}

struct AppEnvironment {

}
