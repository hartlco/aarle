//
//  ArchiveService.swift
//  Aarle
//
//  Created by Martin Hartl on 18.04.22.
//

import Foundation
import Types

enum ArchiveServiceError: Error {
    case invalidEndpoint
    case networkError
    case decodingError
    case missingContent
}

@MainActor
final class ArchiveService: NSObject {
    private let userDefaults: UserDefaults
    private let fileManager: FileManager
    private let session: URLSession

    init(
        userDefaults: UserDefaults,
        fileManager: FileManager = FileManager.default,
        session: URLSession = .shared
    ) {
        self.userDefaults = userDefaults
        self.fileManager = fileManager
        self.session = session

        super.init()
    }

    func archive(link: Link, metadataEndpoint: String?) async throws {
        guard let endpoint = metadataEndpoint?.trimmingCharacters(in: .whitespacesAndNewlines), endpoint.isEmpty == false else {
            throw ArchiveServiceError.invalidEndpoint
        }

        let readableArticle = try await fetchReadableArticle(for: link.url, endpoint: endpoint)

        let fileUUID = UUID()
        let fileURL = getDocumentsDirectory().appendingPathComponent("\(fileUUID.uuidString).html")
        let htmlDocument = makeHTMLDocument(
            content: readableArticle.content,
            title: readableArticle.title ?? link.title,
            originalURL: link.url
        )

        guard let data = htmlDocument.data(using: .utf8) else {
            throw ArchiveServiceError.missingContent
        }

        try data.write(to: fileURL)

        let archiveLink = ArchiveLink(
            id: UUID().uuidString,
            originalLinkId: link.id,
            title: readableArticle.title ?? link.title ?? "",
            description: readableArticle.excerpt ?? link.description ?? "",
            content: htmlDocument,
            dataURL: fileURL,
            tags: link.tags,
            url: link.url,
            dateAdded: link.created
        )

        var links = userDefaults.archiveLinks
        links.append(archiveLink)
        userDefaults.archiveLinks = links
    }

    func delete(link: ArchiveLink) throws {
        if fileManager.fileExists(atPath: link.dataURL.path) {
            try fileManager.removeItem(at: link.dataURL)
        }
        var links = userDefaults.archiveLinks
        links.removeAll(where: { $0.id == link.id })
        userDefaults.archiveLinks = links
    }

    func removeFromList(link: ArchiveLink) {
        var links = userDefaults.archiveLinks
        links.removeAll(where: { $0.id == link.id })
        userDefaults.archiveLinks = links
    }

    func addFailedArchiveLink(for link: Link) {
        let archiveLink = ArchiveLink(
            id: UUID().uuidString,
            originalLinkId: link.id,
            title: link.title,
            description: link.description,
            dataURL: URL(string: "about:blank")!,
            tags: link.tags,
            url: link.url,
            downloadFailed: true,
            dateAdded: link.created
        )
        var links = userDefaults.archiveLinks
        links.append(archiveLink)
        userDefaults.archiveLinks = links
    }

    func update(link: ArchiveLink) {
        var links = userDefaults.archiveLinks
        if let index = links.firstIndex(where: { $0.id == link.id }) {
            links[index] = link
            userDefaults.archiveLinks = links
        }
    }

    var archiveLinks: [ArchiveLink] {
        userDefaults.archiveLinks
    }

    private func getDocumentsDirectory() -> URL {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.co.hartl.Aarle") else {
            // Fallback to local documents directory if App Group is not available
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            return paths[0]
        }
        
        let archiveDirectory = containerURL.appendingPathComponent("Archives")
        
        // Create the directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: archiveDirectory.path) {
            try? FileManager.default.createDirectory(at: archiveDirectory, withIntermediateDirectories: true)
        }
        
        return archiveDirectory
    }
}

private struct ReadableArticle: Sendable {
    let title: String?
    let excerpt: String?
    let content: String
}

private struct MscrapReadableResponse: Codable {
    let title: String?
    let byline: String?
    let excerpt: String?
    let length: Int?
    let siteName: String?
    let content: String?
    let textContent: String?
    let html: String?
    let readable: String?

    var resolvedContent: String? {
        content ?? html ?? readable
    }
}

extension ArchiveService {
    private func makeHTMLDocument(content: String, title: String?, originalURL: URL) -> String {
        let cleanTitle = title ?? originalURL.absoluteString

        return """
        <!doctype html>
        <html lang=\"en\">
        <head>
            <meta charset=\"utf-8\">
            <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">
            <title>\(cleanTitle)</title>
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, \"Segoe UI\", sans-serif; margin: 0 auto; max-width: 700px; padding: 2rem 1.5rem; line-height: 1.6; background: #f5f5f5; color: #1f1f1f; }
                a { color: #007aff; }
                img { max-width: 100%; height: auto; }
                pre { overflow-x: auto; }
            </style>
        </head>
        <body>
            \(content)
        </body>
        </html>
        """
    }

    private func fetchReadableArticle(for url: URL, endpoint: String) async throws -> ReadableArticle {
        guard var components = URLComponents(string: endpoint) else {
            throw ArchiveServiceError.invalidEndpoint
        }

        var path = components.path
        if path.hasSuffix("/") {
            path.removeLast()
        }

        if path.lowercased().hasSuffix("/api") {
            path += "/readable"
        } else {
            path += "/api/readable"
        }

        components.path = path
        components.query = nil

        guard let endpointURL = components.url else {
            throw ArchiveServiceError.invalidEndpoint
        }

        var request = URLRequest(url: endpointURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["url": url.absoluteString]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200 ... 299).contains(httpResponse.statusCode) else {
            throw ArchiveServiceError.networkError
        }

        let readableResponse: MscrapReadableResponse
        do {
            readableResponse = try JSONDecoder().decode(MscrapReadableResponse.self, from: data)
        } catch {
            throw ArchiveServiceError.decodingError
        }

        guard let content = readableResponse.resolvedContent else {
            throw ArchiveServiceError.missingContent
        }

        return ReadableArticle(
            title: readableResponse.title,
            excerpt: readableResponse.excerpt,
            content: content
        )
    }
}

extension UserDefaults {
    var archiveLinks: [ArchiveLink] {
        get {
            guard let data = data(forKey: #function),
                  let tags = try? PropertyListDecoder().decode([ArchiveLink].self, from: data)
            else {
                return []
            }
            return tags
        }
        set {
            guard let data = try? PropertyListEncoder().encode(newValue) else {
                return
            }

            set(data, forKey: #function)
        }
    }
}
