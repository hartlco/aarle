import KeychainAccess
import SwiftUI
import Settings
import Types
import List
import Navigation
import Archive

struct LinkCommands: Commands {
    @ObservedObject var navigationState: NavigationState
    @ObservedObject var listState: ListState
    @ObservedObject var archiveState: ArchiveState
    let pasteboard: Pasteboard

    var body: some Commands {
        CommandMenu("Link") {
            Button("Edit link") {
                guard let selectedLinkID = navigationState.selectedLink?.id,
                      let selectedLink = listState.link(for: selectedLinkID)
                else {
                    return
                }

                navigationState.presentedEditLink = selectedLink
            }
            .keyboardShortcut("e", modifiers: [.command])
            .disabled(navigationState.selectedLink == nil)
            Button("Copy link to clipboard") {
                guard let selectedLinkID = navigationState.selectedLink?.id,
                      let selectedLink = listState.link(for: selectedLinkID)
                else {
                    return
                }

                pasteboard.copyToPasteboard(string: selectedLink.url.absoluteString)
            }
            .keyboardShortcut("C", modifiers: [.command, .shift])
            .disabled(navigationState.selectedLink == nil)
            Button("Delete") {
                if let selectedLinkID = navigationState.selectedLink?.id,
                   let selectedLink = listState.link(for: selectedLinkID) {
                    Task {
                        await listState.delete(link: selectedLink)
                        navigationState.selectedLink = nil
                    }
                } else if let selectedArchiveLinkID = navigationState.selectedArchiveLink {
                    do {
                        try archiveState.deleteLink(link: selectedArchiveLinkID)
                        navigationState.selectedArchiveLink = nil
                    } catch {
                        // TODO: Error handling
                    }
                }
            }
            .keyboardShortcut(.delete, modifiers: [.command])
            .disabled(navigationState.selectedLink == nil && navigationState.selectedArchiveLink == nil)
        }
    }
}
