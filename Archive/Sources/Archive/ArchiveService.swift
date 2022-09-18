//
//  ArchiveService.swift
//  Aarle
//
//  Created by Martin Hartl on 18.04.22.
//

import Foundation
import WebKit
import Types

final class ArchiveService: NSObject {
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults

        super.init()
    }

    func archive(link: Link) async throws {
        let archiver = await URLArchiver()
        let data = try await archiver.archive(url: link.url)
        print(data)
        let fileUUID = UUID()
        let fileURL = getDocumentsDirectory().appendingPathComponent("\(fileUUID.uuidString).data")

        do {
            try data.write(to: fileURL)
            print(fileURL)
        } catch {
            print(error.localizedDescription)
        }

        let archiveLink = ArchiveLink(
            id: link.id,
            title: link.title ?? "",
            description: link.description ?? "",
            dataURL: fileURL,
            tags: link.tags,
            url: link.url
        )

        var links = userDefaults.archiveLinks
        links.append(archiveLink)
        userDefaults.archiveLinks = links
    }

    var archiveLinks: [ArchiveLink] {
        userDefaults.archiveLinks
    }

    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}

@MainActor final class URLArchiver: NSObject, WKNavigationDelegate {
    private let webView = WKWebView()

    private var didArchive: ((URL?, Data?) -> Void)?

    @MainActor func archive(url: URL) async throws -> Data {
        webView.navigationDelegate = self
        webView.load(.init(url: url))
        return try await withCheckedThrowingContinuation { continuation in
            didArchive = { _, data in
                // TODO: Error handling
                if let data = data {
                    continuation.resume(returning: data)
                }
            }
        }
    }

    func webView(_ webView: WKWebView, didFinish _: WKNavigation!) {
        webView.createWebArchiveData { [weak self] result in
            self?.didArchive?(webView.url, try? result.get())
        }
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