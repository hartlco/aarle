import Swift

public struct Tag: Codable, Identifiable, Equatable, Hashable {
    public let name: String
    public let occurrences: Int?

    public var id: String {
        return name
    }

    public init(name: String, occurrences: Int? = nil) {
        self.name = name
        self.occurrences = occurrences
    }
}

public extension Tag {
    static func from(dictionary: [String: Int]) -> [Tag] {
        dictionary.map { key, value in
            Tag(name: key, occurrences: value)
        }
    }
}
