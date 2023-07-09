import Foundation
import Types
import Observation

public enum DetailNavigationDestination: Hashable {
    case link
    case empty
}

@Observable
public final class NavigationState {
    public var selectedListType: ListType? = .all

    public var showsSettings = false {
        didSet {
            if showsSettings {
                #if os(macOS)
                    WindowRoutes.settings.open()
                #endif
            }
        }
    }

    public var selectedLink: Link? = nil

    public var detailNavigationStack: [Link] = []

    public var showLinkEditorSidebar = false

    public var selectedArchiveLink: ArchiveLink? = nil {
        didSet {
            print("Selected Archive Link")
        }
    }

    public var selectedTag: Tag? = nil

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
}
