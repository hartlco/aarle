//
//  ShareViewController.swift
//  Aarlo-macOS-ShareExtension
//
//  Created by martinhartl on 08.01.22.
//

import Cocoa
import SwiftUI

@MainActor
class ShareViewController: NSViewController {
    let linkStore = LinkStore(client: .init(), tagScope: nil)
    let tagStore = TagStore(client: .init())

    override func loadView() {
        view = NSView(frame: NSMakeRect(0.0, 0.0, 300, 300))

        guard let inputItems = self.extensionContext?.inputItems as? [NSExtensionItem] else {
            // TODO: Show error
            return
        }

        Task {
            var title: String?
            var description: String?
            var url: URL?

            for item in inputItems {
                for attachment in (item.attachments ?? []) {
                    let websiteInformation = try? await attachment.loadWebsiteInformation()
                    title = websiteInformation?.title ?? title
                    description = websiteInformation?.description ?? description

                    let loadedURL = try? await attachment.loadURL()
                    url = loadedURL ?? url
                }
            }

            self.showView(for: url, title: title, description: description)
        }
    }

    @MainActor
    private func showView(for url: URL?, title: String?, description: String?) {
        let addView = LinkAddView(
            linkStore: linkStore,
            urlString: url?.absoluteString ?? "",
            title: title ?? "",
            description: description ?? ""
        ) {
            self.send(self)
        }.onDisappear {
            self.cancel(self)
        }.environmentObject(tagStore)
        let hosting = NSHostingView(rootView: addView)
        hosting.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hosting.topAnchor.constraint(equalTo: view.topAnchor),
        ])
    }

    @IBAction func send(_ sender: AnyObject?) {
        let outputItem = NSExtensionItem()
        // Complete implementation by setting the appropriate value on the output item
    
        let outputItems = [outputItem]
        self.extensionContext!.completeRequest(returningItems: outputItems, completionHandler: nil)
    }

    @IBAction func cancel(_ sender: AnyObject?) {
        let cancelError = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil)
        self.extensionContext!.cancelRequest(withError: cancelError)
    }
}
