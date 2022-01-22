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
}

extension WebsiteInformation {
    init?(fromJavaScriptPreprocessing dictionary: NSDictionary?) {
        guard let dictionary = dictionary?["NSExtensionJavaScriptPreprocessingResultsKey"] as? [String: String] else { return nil }

        self.title = dictionary["title"] as? String
        self.description = dictionary["description"] as? String
    }
}
