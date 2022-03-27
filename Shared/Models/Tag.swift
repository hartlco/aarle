//
//  Tag.swift
//  Aarlo
//
//  Created by martinhartl on 14.01.22.
//

import Swift

struct Tag: Codable, Identifiable, Equatable, Hashable {
    let name: String
    let occurrences: Int?

    var id: String {
        return name
    }
}

extension Tag {
    static func from(dictionary: [String: Int]) -> [Tag] {
        dictionary.map { key, value in
            Tag(name: key, occurrences: value)
        }
    }
}
