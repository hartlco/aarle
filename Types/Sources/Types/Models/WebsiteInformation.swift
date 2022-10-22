import Foundation

public struct WebsiteInformation: Codable {
    public init(title: String? = nil, description: String? = nil, baseURI: String? = nil) {
        self.title = title
        self.description = description
        self.baseURI = baseURI
    }

    public var title: String?
    public var description: String?
    public var baseURI: String?
}

public extension WebsiteInformation {
    init?(fromJavaScriptPreprocessing dictionary: NSDictionary?) {
        guard let dictionary = dictionary?["NSExtensionJavaScriptPreprocessingResultsKey"] as? [String: String]
        else { return nil }

        title = dictionary["title"]
        description = dictionary["description"]
        baseURI = dictionary["baseURI"]
    }
}
