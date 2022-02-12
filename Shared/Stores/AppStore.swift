//
//  AppStore.swift
//  Aarlo
//
//  Created by martinhartl on 28.01.22.
//

import Foundation
import SwiftUI

final class AppStore: ObservableObject {
    enum Action {
        case setSelectedLinkID(String?)
        case setSelectedListType(ListType?)
        case showLinkEditorSidebar
        case hideLinkEditorSidebar

        case showEditLink(Link)
        case hideEditLink

        case showAddView
        case hideAddView
        case showSettings
        case hideSettings
    }

    struct AppState {
        var selectedListType: ListType?
        var selectedLinkID: String?
        var presentedEditLink: Link?
        var showLinkEditorSidebar = false
        var showsAddView = false
        var showsSettings = false
    }

    static func reduce(action: Action, into state: inout AppState) {
        switch action {
        case let .setSelectedLinkID(id):
            state.selectedLinkID = id
        case let .setSelectedListType(type):
            state.selectedListType = type
        case .showLinkEditorSidebar:
            state.showLinkEditorSidebar = true
        case .hideLinkEditorSidebar:
            state.showLinkEditorSidebar = false
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
        case .hideSettings:
            state.showsSettings = false
        case let .showEditLink(link):
            state.presentedEditLink = link
        case .hideEditLink:
            state.presentedEditLink = nil
        }
    }

    func reduce(_ action: Action) {
        Self.reduce(action: action, into: &state)
    }

    #if os(macOS)
    @Published var state: AppState = AppState(selectedListType: ListType.all)
    #else
    @Published var state: AppState = AppState()
    #endif

    var selectedLinkID: Binding<String?> {
        Binding { [weak self] in
            return self?.state.selectedLinkID
        } set: { [weak self] id in
            guard let self = self else { return }
            self.reduce(.setSelectedLinkID(id))
        }
    }

//    var selectedLink: Binding<Link?> {
//        Binding { [weak self] in
//            return self?.state.selectedLink
//        } set: { [weak self] link in
//            guard let self = self else { return }
//            self.reduce(.setSelectedLink(link))
//        }
//    }

    var selectedListType: Binding<ListType?> {
        Binding { [weak self] in
            return self?.state.selectedListType
        } set: { [weak self] type in
            guard let self = self else { return }
            self.reduce(.setSelectedListType(type))
        }
    }

    var presentedEditLink: Binding<Link?> {
        Binding { [weak self] in
            return self?.state.presentedEditLink
        } set: { [weak self] link in
            guard let self = self else { return }

            if let link = link {
                self.reduce(.showEditLink(link))
            } else {
                self.reduce(.hideEditLink)
            }
        }
    }

    var showLinkEditorSidebar: Bool { state.showLinkEditorSidebar }

    var showsAddView: Binding<Bool> {
        Binding { [weak self] in
            return self?.state.showsAddView ?? false
        } set: { [weak self] show in
            guard let self = self else { return }
            if show {
                self.reduce(.showAddView)
            } else {
                self.reduce(.hideAddView)
            }
        }
    }

    var showsSettings: Binding<Bool> {
        Binding { [weak self] in
            return self?.state.showsSettings ?? false
        } set: { [weak self] showsSettings in
            guard let self = self else { return }
            if showsSettings {
                self.reduce(.showSettings)
            } else {
                self.reduce(.hideSettings)
            }
        }
    }
}
