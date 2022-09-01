//
//  WebsiteInformation.swift
//  Aarlo
//
//  Created by martinhartl on 21.01.22.
//

import Foundation

struct WebsiteInformation: Codable {
    var title: String?
    var description: String?
    var baseURI: String?
}

extension WebsiteInformation {
    init?(fromJavaScriptPreprocessing dictionary: NSDictionary?) {
        guard let dictionary = dictionary?["NSExtensionJavaScriptPreprocessingResultsKey"] as? [String: String] else { return nil }

        title = dictionary["title"]
        description = dictionary["description"]
        baseURI = dictionary["baseURI"]
    }
}
