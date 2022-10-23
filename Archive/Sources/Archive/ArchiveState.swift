import Foundation
import Types

public final class ArchiveState: ObservableObject, ArchiveStateProtocol {
    public enum ArchiveStateError: Error {
        case unableToDelete
    }

    @Published public var archiveLinks: [ArchiveLink]

    private let archiveService: ArchiveService

    public init(
        userDefaults: UserDefaults
    ) {
        self.archiveLinks = userDefaults.archiveLinks
        self.archiveService = ArchiveService(userDefaults: userDefaults)
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
