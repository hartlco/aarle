import Foundation

public enum ListType: Hashable, Equatable, Sendable {
    case all
    case tagScoped(Tag)
    case downloaded
    case tags(selectedTag: Tag?)

    public var scopedTags: [String] {
        switch self {
        case .all:
            return []
        case let .tagScoped(tag):
            return [tag.name]
        case .downloaded:
            return []
        case .tags(let selectedTag):
            if let selectedTag {
                return [selectedTag.name]
            }
            return []
        }
    }
}
