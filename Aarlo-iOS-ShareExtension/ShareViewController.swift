//
//  ShareViewController.swift
//  Aarlo-iOS-ShareExtension
//
//  Created by martinhartl on 22.01.22.
//

import UIKit
import SwiftUI
import Social

final class ShareViewController: UIViewController {
    let linkStore = LinkStore(client: .init(), tagScope: nil)
    let tagStore = TagStore(client: .init())

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let inputItems = self.extensionContext?.inputItems as? [NSExtensionItem] else {
            // TODO: Show error
            return
        }

        Task {
            var title: String?
            var description: String?
            var urlString: String?

            for item in inputItems {
                for attachment in (item.attachments ?? []) {
                    let websiteInformation = try? await attachment.loadWebsiteInformation()
                    title = websiteInformation?.title ?? title
                    description = websiteInformation?.description ?? description
                    urlString = websiteInformation?.baseURI ?? urlString

                    let loadedURL = try? await attachment.loadURL()
                    urlString = loadedURL?.absoluteString ?? urlString
                }
            }

            self.showView(for: urlString, title: title, description: description)
        }
    }

    @MainActor
    private func showView(for urlString: String?, title: String?, description: String?) {
        let addView = LinkAddView(
            linkStore: linkStore,
            tagStore: tagStore,
            urlString: urlString ?? "",
            title: title ?? "",
            description: description ?? ""
        ) {
            self.send(self)
        }.onDisappear {
            self.cancel(self)
        }
        let hosting = UIHostingController(rootView: addView)
        self.addChild(hosting)
        self.view.addSubview(hosting.view)
        hosting.didMove(toParent: self)

        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
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
