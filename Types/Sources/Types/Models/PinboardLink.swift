import Foundation

public struct PinboardLink: Codable, Hashable {
    public init(
        href: String,
        description: String? = nil,
        extended: String? = nil,
        tags: String? = nil,
        time: Date,
        shared: String
    ) {
        self.href = href
        self.description = description
        self.extended = extended
        self.tags = tags
        self.time = time
        self.shared = shared
    }

    public let href: String
    public let description: String?
    public let extended: String?
    public let tags: String?
    public let time: Date
    public let shared: String
}

public extension Link {
    static func fromPinboardLink(link: PinboardLink) -> Link {
        Link(
            id: link.href,
            url: URL(string: link.href)!,
            title: link.description,
            description: link.extended,
            tags: link.tags?.components(separatedBy: " ") ?? [],
            private: link.shared == "yes",
            created: link.time
        )
    }
}
