//
//  ShareViewController.swift
//  Aarlo-iOS-ShareExtension
//
//  Created by martinhartl on 22.01.22.
//

import KeychainAccess
import Social
import SwiftUI
import UIKit
import Tag

final class ShareViewController: UIViewController {
    static let keyChain = Keychain(service: "co.hartl.Aarle")

    var appState: OverallAppState

    init(appState: OverallAppState) {
        self.appState = appState
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let overallAppState = OverallAppState(
        client: UniversalClient(keychain: keyChain),
        keychain: keyChain
    )

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let inputItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            // TODO: Show error
            return
        }

        Task {
            var title: String?
            var description: String?
            var urlString: String?

            for item in inputItems {
                for attachment in item.attachments ?? [] {
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
            overallAppState: overallAppState, urlString: urlString ?? "",
            title: title ?? "",
            description: description ?? ""
        ).onDisappear {
            self.send(self)
        }

        let hosting = UIHostingController(rootView: addView)
        addChild(hosting)
        view.addSubview(hosting.view)
        hosting.didMove(toParent: self)

        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor)
        ])
    }

    @IBAction func send(_: AnyObject?) {
        let outputItem = NSExtensionItem()
        // Complete implementation by setting the appropriate value on the output item

        let outputItems = [outputItem]
        extensionContext!.completeRequest(returningItems: outputItems, completionHandler: nil)
    }

    @IBAction func cancel(_: AnyObject?) {
        let cancelError = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil)
        extensionContext!.cancelRequest(withError: cancelError)
    }
}
