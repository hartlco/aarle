import KeychainAccess
import SwiftUI
import Settings
import Types
import List
import Navigation
import Archive

struct LinkCommands: Commands {
    var navigationState: NavigationState
    var listState: ListState
    var archiveState: ArchiveState
    let pasteboard: Pasteboard

    var body: some Commands {
        CommandMenu("Link") {
            Button("Edit link") {
                navigationState.editSelectedLink()
            }
            .keyboardShortcut("e", modifiers: [.command])
            .disabled(navigationState.selectedDetailDestination?.isLinkSelected != true)
            Button("Copy link to clipboard") {
                guard let url = navigationState.selectedDetailDestination?.url else { return }
                pasteboard.copyToPasteboard(string: url.absoluteString)
            }
            .keyboardShortcut("C", modifiers: [.command, .shift])
            .disabled(navigationState.selectedDetailDestination?.isLinkSelected != true)
            Button("Delete") {
                switch navigationState.selectedDetailDestination {
                case .link(let link):
                    Task {
                        await listState.delete(link: link)
                        navigationState.selectedDetailDestination = .empty
                    }
                case .archiveLink(let archiveLink):
                    do {
                        try archiveState.deleteLink(link: archiveLink)
                        navigationState.selectedDetailDestination = .empty
                    } catch {
                        // TODO: Error handling
                    }
                case .tag:
                    return
                case .empty:
                    return
                case .none:
                    return
                }
            }
            .keyboardShortcut(.delete, modifiers: [.command])
            .disabled(navigationState.selectedDetailDestination?.isLinkSelected != true)
        }
    }
}
