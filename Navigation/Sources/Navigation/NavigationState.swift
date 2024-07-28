import Foundation
import Types
import Observation

public enum DetailNavigationDestination: Hashable {
    case link(Link)
    case archiveLink(ArchiveLink)
    case tag(Tag)
    case empty

    public var isLinkSelected: Bool {
        return url != nil
    }

    public var url: URL? {
        switch self {
        case .link(let link):
            return link.url
        case .archiveLink(let archiveLink):
            return archiveLink.url
        case .tag, .empty:
            return nil
        }
    }
}

@Observable
public final class NavigationState {
    public var selectedListType: ListType? = .all
    public var selectedDetailDestination: DetailNavigationDestination? = .empty
    public var showsSettings = false {
        didSet {
            if showsSettings {
                #if os(macOS)
                    WindowRoutes.settings.open()
                #endif
            }
        }
    }

    public var detailNavigationStack: [DetailNavigationDestination] = []
    public var showLinkEditorSidebar = false
    public var presentedEditLink: Link? = nil {
        didSet {
            if presentedEditLink != nil {
#if os(macOS)
                WindowRoutes.editLink.open()
#endif
            }
        }
    }
    public var showsAddView = false {
        didSet {
            if showsAddView {
#if os(macOS)
                WindowRoutes.addLink.open()
#endif
            }
        }
    }

    public init() { }

    public func editSelectedLink() {
        switch selectedDetailDestination {
        case .link(let link):
            self.presentedEditLink = link
        case .archiveLink:
            return
        case .tag:
            return
        case .empty:
            return
        case .none:
            return
        }
    }
}
