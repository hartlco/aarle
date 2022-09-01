#if os(macOS)
    import AppKit
#endif

enum WindowRoutes: String {
    case addLink
    case editLink
    case settings

    #if os(macOS)
        func open() {
            if let url = URL(string: "aarle://\(rawValue)") {
                NSWorkspace.shared.open(url)
            }
        }
    #endif
}
