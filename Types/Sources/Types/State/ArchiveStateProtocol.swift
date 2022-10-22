import Foundation

public protocol ArchiveStateProtocol: ObservableObject {
    var archiveLinks: [ArchiveLink] { get }

    func archiveLink(link: Link) async
}
