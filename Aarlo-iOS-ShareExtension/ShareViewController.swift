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
    override func viewDidLoad() {
        super.viewDidLoad()

        let vc  = UIHostingController(rootView: Text("ho"))
        self.addChild(vc)
        self.view.addSubview(vc.view)
        vc.didMove(toParent: self)

        vc.view.translatesAutoresizingMaskIntoConstraints = false
        vc.view.heightAnchor.constraint(equalTo: self.view.heightAnchor).isActive = true
        vc.view.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        vc.view.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        vc.view.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        vc.view.backgroundColor = .systemBackground

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
        }
    }
}
