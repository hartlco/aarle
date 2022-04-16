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

let appReducer: ReduceFunction<AppState, AppAction, AppEnvironment> = { state, action, environment, handler in
    switch action {
    case let .setSelectedLinkID(id):
        handler.handle(.change { $0.selectedLinkID = id })
    case let .setSelectedListType(type):
        handler.handle(.change { $0.selectedListType = type })
    case .showLinkEditorSidebar:
        handler.handle(.change { $0.showLinkEditorSidebar = true })
    case .hideLinkEditorSidebar:
        handler.handle(.change { $0.showLinkEditorSidebar = false })
    case let .setShowLinkEditorSidebar(value):
        handler.handle(.change { $0.showLinkEditorSidebar = value })
    case let .setShowAddView(value):
        handler.handle(.change { $0.showsAddView = value })
    case .showAddView:
        handler.handle(.change { $0.showsAddView = true })
#if os(macOS)
        // TODO: Move into side-effect
        WindowRoutes.addLink.open()
#endif
    case .hideAddView:
        handler.handle(.change { $0.showsAddView = false })
    case .showSettings:
        handler.handle(.change { $0.showsSettings = true })

#if os(macOS)
        // TODO: Move into side-effect
        WindowRoutes.settings.open()
#endif
    case let .setShowSettings(value):
        handler.handle(.change { $0.showsSettings = value })
    case .hideSettings:
        handler.handle(.change { $0.showsSettings = false })
    case let .setEditLink(link):
        handler.handle(.change { $0.showsSettings = false })
    case let .showEditLink(link):
        handler.handle(.change { $0.presentedEditLink = link })
    case .hideEditLink:
        handler.handle(.change { $0.presentedEditLink = nil })
    }
}

struct AppEnvironment {

}
