//
//  ShaarliClaims.swift
//  Aarlo
//
//  Created by martinhartl on 02.01.22.
//

import Foundation
import SwiftJWT

struct ShaarliClaims: Claims {
    let iat: Date
}
