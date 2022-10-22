import KeychainAccess
import SwiftUI
import Settings
import Types
import List
import Navigation

struct LinkCommands: Commands {
    @ObservedObject var navigationState: NavigationState
    @ObservedObject var listState: ListState
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
                guard let selectedLinkID = navigationState.selectedLink?.id,
                      let selectedLink = listState.link(for: selectedLinkID)
                else {
                    return
                }

                // TODO: Clear selection after delete
                Task {
                    await listState.delete(link: selectedLink)
                }
            }
            .keyboardShortcut(.delete, modifiers: [.command])
            .disabled(navigationState.selectedLink == nil)
        }
    }
}
