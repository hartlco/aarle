//
//  UserDefaults+Suite.swift
//  Aarlo
//
//  Created by martinhartl on 18.01.22.
//

import Foundation

extension UserDefaults {
    static var suite: UserDefaults {
        guard let defaults = UserDefaults(suiteName: "group.co.hartl.aarlo") else {
            fatalError("UserDefaults suite could not be created")
        }

        return defaults
    }
}
