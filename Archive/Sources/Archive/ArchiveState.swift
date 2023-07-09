import Foundation
import Types
import Observation

@Observable
public final class ArchiveState: ArchiveStateProtocol {
    public enum ArchiveStateError: Error {
        case unableToDelete
    }

    public var archiveLinks: [ArchiveLink] = []

    private let archiveService: ArchiveService

    public init(
        userDefaults: UserDefaults
    ) {
        self.archiveService = ArchiveService(userDefaults: userDefaults)

        archiveLinks = userDefaults.archiveLinks
    }

    public func archiveLink(link: Link) async {
        do {
            try await archiveService.archive(link: link)
            let newLinks = archiveService.archiveLinks
            archiveLinks = newLinks
        } catch {
            print(error)
        }
    }

    public func deleteLink(link: ArchiveLink) throws {
        do {
            try archiveService.delete(link: link)
            self.archiveLinks.removeAll(where: {$0.id == link.id })
        } catch {
            throw ArchiveStateError.unableToDelete
        }
    }
}
