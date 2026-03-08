import Foundation

public struct ArchiveLink: Codable, Identifiable, Hashable {
    public init(
        id: String,
        originalLinkId: String? = nil,
        title: String? = nil,
        description: String? = nil,
        content: String? = nil,
        dataURL: URL,
        tags: [String],
        url: URL,
        downloadFailed: Bool = false
    ) {
        self.id = id
        self.originalLinkId = originalLinkId
        self.title = title
        self.description = description
        self.content = content
        self.dataURL = dataURL
        self.tags = tags
        self.url = url
        self.downloadFailed = downloadFailed
    }

    public var id: String
    public var originalLinkId: String?
    public var title: String?
    public var description: String?
    public var content: String?
    public var dataURL: URL
    public var tags: [String]
    public var url: URL
    public var downloadFailed: Bool

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        originalLinkId = try container.decodeIfPresent(String.self, forKey: .originalLinkId)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        content = try container.decodeIfPresent(String.self, forKey: .content)
        dataURL = try container.decode(URL.self, forKey: .dataURL)
        tags = try container.decode([String].self, forKey: .tags)
        url = try container.decode(URL.self, forKey: .url)
        downloadFailed = try container.decodeIfPresent(Bool.self, forKey: .downloadFailed) ?? false
    }
}
