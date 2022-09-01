//
//  Pasteboard.swift
//  Aarlo
//
//  Created by martinhartl on 09.01.22.
//

import Foundation
#if os(macOS)
    import AppKit
#elseif os(iOS)
    import UIKit
#endif

protocol Pasteboard {
    func copyToPasteboard(string: String)
}

final class DefaultPasteboard: Pasteboard {
    #if os(macOS)
        let pasteboard: NSPasteboard

        init(pasteboard: NSPasteboard = .general) {
            self.pasteboard = pasteboard
        }

    #elseif os(iOS)
        let pasteboard: UIPasteboard

        init(pasteboard: UIPasteboard = .general) {
            self.pasteboard = pasteboard
        }
    #endif

    func copyToPasteboard(string: String) {
        #if os(macOS)
            pasteboard.clearContents()
            pasteboard.setData(string.data(using: .utf8), forType: NSPasteboard.PasteboardType.string)
        #elseif os(iOS)
            pasteboard.string = string
        #endif
    }
}
