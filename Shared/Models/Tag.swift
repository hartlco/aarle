//
//  Tag.swift
//  Aarlo
//
//  Created by martinhartl on 14.01.22.
//

import Swift

struct Tag: Codable, Identifiable, Equatable {
    let name: String
    let occurrences: Int

    var id: String {
        return name
    }
}
