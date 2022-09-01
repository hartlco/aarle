import Foundation

public struct ArchiveLink: Codable, Identifiable, Hashable {
    public init(id: String, title: String? = nil, description: String? = nil, dataURL: URL, tags: [String], url: URL) {
        self.id = id
        self.title = title
        self.description = description
        self.dataURL = dataURL
        self.tags = tags
        self.url = url
    }
    
    public var id: String
    public var title: String?
    public var description: String?
    public var dataURL: URL
    public var tags: [String]
    public var url: URL
    
    
}
