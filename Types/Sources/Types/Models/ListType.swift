import Foundation

public enum ListType: Hashable, Equatable, Sendable {
    case all
    case tagScoped(Tag)
    case downloaded

    public var scopedTags: [String] {
        switch self {
        case .all:
            return []
        case let .tagScoped(tag):
            return [tag.name]
        case .downloaded:
            return []
        }
    }
}
