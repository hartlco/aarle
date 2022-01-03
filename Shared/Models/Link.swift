//
//  Link.swift
//  Aarlo
//
//  Created by martinhartl on 02.01.22.
//

import Foundation

struct Link: Codable, Identifiable {
    let id: Int
    let url: URL
    let title: String?
    let description: String?
    let tags: [String]

    // TODO: Handle Date

//    let created: Date
//    let updated: Date
}
