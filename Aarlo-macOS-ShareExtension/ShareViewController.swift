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
    
        // Insert code here to customize the view
        let item = self.extensionContext!.inputItems[0] as! NSExtensionItem
        if let attachments = item.attachments {
            NSLog("Attachments = %@", attachments as NSArray)
        } else {
            NSLog("No Attachments")
        }

        let addView = LinkAddView(linkStore: linkStore, tagStore: tagStore)
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
