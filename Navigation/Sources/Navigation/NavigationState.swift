import Foundation
import Types

public final class NavigationState: ObservableObject {
    #if os(macOS)
        @Published public var selectedListType: ListType? = .all {
            didSet {
                print("Didset selectedListType: \(selectedListType)")
            }
        }
    #else
        @Published public var selectedListType: ListType?
    #endif

    @Published public var showsSettings = false {
        didSet {
            if showsSettings {
                #if os(macOS)
                    WindowRoutes.settings.open()
                #endif
            }
        }
    }

    @Published public var selectedLink: Link? {
        didSet {
            print("Didset selectedLink: \(selectedLink?.url.absoluteString ?? "No URL")")

            if let selectedLink {
                selectedLinkStack = [selectedLink]
            } else {
                selectedLinkStack = []
            }
        }
    }
    @Published public var selectedLinkStack: [Link] = []

    @Published public var showLinkEditorSidebar = false

    @Published public var selectedArchiveLink: ArchiveLink?

    @Published public var presentedEditLink: Link? {
        didSet {
            if presentedEditLink != nil {
#if os(macOS)
                WindowRoutes.editLink.open()
#endif
            }
        }
    }
    @Published public var showsAddView = false {
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
