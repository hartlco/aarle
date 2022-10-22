import Foundation
import Types

public final class ArchiveState: ObservableObject, ArchiveStateProtocol {
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
}
