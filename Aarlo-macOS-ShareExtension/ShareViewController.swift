//
//  ShareViewController.swift
//  Aarlo-macOS-ShareExtension
//
//  Created by martinhartl on 08.01.22.
//

import Cocoa
import SwiftUI

class ShareViewController: NSViewController {
    let linkStore = LinkStore(client: .init(), tagScope: nil)
    let tagStore = TagStore(client: .init())

    override func loadView() {
        view = NSView(frame: NSMakeRect(0.0, 0.0, 300, 300))

        let item = self.extensionContext!.inputItems[0] as! NSExtensionItem
        if let attachments = item.attachments {
            if let attachment = attachments.first {
                _ = attachment.loadObject(ofClass: URL.self) { url, error in
                    guard let url = url else {
                        return
                    }

                    DispatchQueue.main.async {
                        self.showView(for: url)
                        print(url)
                    }
                }
            }
        } else {
            fatalError("No URL found")
        }
    }

    private func showView(for url: URL) {
        let addView = LinkAddView(linkStore: linkStore, tagStore: tagStore, urlString: url.absoluteString)
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
