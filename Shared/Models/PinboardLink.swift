//
//  PinboardLink.swift
//  Aarlo
//
//  Created by martinhartl on 29.01.22.
//

import Foundation

struct PinboardLink: Codable, Hashable {
    let href: String
    let description: String?

    let tags: String?
}
