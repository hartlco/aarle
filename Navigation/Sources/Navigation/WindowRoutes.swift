#if os(macOS)
import AppKit
#endif

public enum WindowRoutes: String {
    case addLink
    case editLink
    case settings

#if os(macOS)
    public func open() {
        if let url = URL(string: "aarle://\(rawValue)") {
            NSWorkspace.shared.open(url)
        }
    }
#endif
}
