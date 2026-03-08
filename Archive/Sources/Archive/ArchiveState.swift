import Foundation
import Types
import Observation

@MainActor
@Observable
public final class ArchiveState: ArchiveStateProtocol {
    public enum ArchiveStateError: Error {
        case unableToDelete
    }

    public struct ArchiveError: Identifiable, Equatable {
        public let id = UUID()
        public let title: String
        public let message: String
    }

    public var archiveLinks: [ArchiveLink] = []
    public var presentedError: ArchiveError? = nil
    public var isSyncing: Bool = false
    public var syncProgress: String = ""
    public var pendingDownloadIds: Set<String> = []

    private let archiveService: ArchiveService
    private let metadataEndpointProvider: () -> String?

    public init(
        userDefaults: UserDefaults,
        metadataEndpointProvider: @escaping () -> String? = { nil }
    ) {
        self.archiveService = ArchiveService(userDefaults: userDefaults)
        self.metadataEndpointProvider = metadataEndpointProvider

        archiveLinks = userDefaults.archiveLinks
    }

    public func archiveLink(link: Link) async {
        do {
            let endpoint = metadataEndpointProvider()
            try await archiveService.archive(link: link, metadataEndpoint: endpoint)
            let newLinks = archiveService.archiveLinks
            presentedError = nil
            archiveLinks = newLinks
        } catch {
            presentedError = ArchiveError(
                title: "Download Failed",
                message: errorMessage(for: error)
            )
        }
    }

    public func deleteLink(link: ArchiveLink) throws {
        do {
            if !link.downloadFailed {
                try archiveService.delete(link: link)
            } else {
                archiveService.removeFromList(link: link)
            }
            self.archiveLinks.removeAll(where: { $0.id == link.id })
        } catch {
            throw ArchiveStateError.unableToDelete
        }
    }

    public func updateLink(link: ArchiveLink) {
        archiveService.update(link: link)
        if let index = archiveLinks.firstIndex(where: { $0.id == link.id }) {
            archiveLinks[index] = link
        }
    }

    public func refresh() {
        archiveLinks = archiveService.archiveLinks
    }

    public func clearAllArchives() {
        for link in archiveLinks {
            try? archiveService.delete(link: link)
        }
        archiveLinks = []
    }

    public func syncUnreadBookmarks(unreadLinks: [Link]) async {
        isSyncing = true
        defer {
            isSyncing = false
            syncProgress = ""
            pendingDownloadIds = []
        }

        let unreadIds = Set(unreadLinks.map { $0.id })

        // Remove archives whose original link is no longer unread
        let toRemove = archiveLinks.filter { archiveLink in
            guard let originalId = archiveLink.originalLinkId else { return false }
            return !unreadIds.contains(originalId)
        }
        for link in toRemove {
            try? deleteLink(link: link)
        }

        // Remove previously failed downloads so they get retried
        let failedLinks = archiveLinks.filter { $0.downloadFailed }
        for link in failedLinks {
            try? deleteLink(link: link)
        }

        // Only consider successfully downloaded IDs as existing
        let successfulIds = Set(archiveLinks.compactMap { $0.originalLinkId })
        let linksToDownload = unreadLinks.filter { !successfulIds.contains($0.id) }
        guard !linksToDownload.isEmpty else { return }

        pendingDownloadIds = Set(linksToDownload.map { $0.id })
        let endpoint = metadataEndpointProvider()
        let total = linksToDownload.count

        for (index, link) in linksToDownload.enumerated() {
            syncProgress = "Downloading \(index + 1) of \(total)..."
            do {
                try await archiveService.archive(link: link, metadataEndpoint: endpoint)
            } catch {
                archiveService.addFailedArchiveLink(for: link)
            }
            pendingDownloadIds.remove(link.id)
            archiveLinks = archiveService.archiveLinks
        }
    }

    private func errorMessage(for error: Error) -> String {
        if let archiveError = error as? ArchiveServiceError {
            switch archiveError {
            case .invalidEndpoint:
                return "Set the mscrap endpoint in Settings before downloading for offline reading."
            case .networkError:
                return "Unable to reach the mscrap readable endpoint. Check your connection and try again."
            case .decodingError:
                return "Received an unexpected response from mscrap."
            case .missingContent:
                return "mscrap couldn't generate a readable version for this page."
            }
        }

        return error.localizedDescription
    }
}
