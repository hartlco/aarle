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
        case setSelectedLink(Link?)
        case showLinkEditorSidebar
        case hideLinkEditorSidebar
        case showAddView
        case hideAddView
        case showSettings
        case hideSettings
    }

    struct AppState {
        var selectedLink: Link?
        var showLinkEditorSidebar = false
        var showsAddView = false
        var showsSettings = false
    }

    static func reduce(action: Action, into state: inout AppState) {
        switch action {
        case let .setSelectedLink(link):
            state.selectedLink = link
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
        }
    }

    func reduce(_ action: Action) {
        Self.reduce(action: action, into: &state)
    }

    @Published var state: AppState = AppState()

    var selectedLink: Binding<Link?> {
        Binding { [weak self] in
            return self?.state.selectedLink
        } set: { [weak self] link in
            guard let self = self else { return }
            self.reduce(.setSelectedLink(link))
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
