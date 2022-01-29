//
//  PinboardClient.swift
//  Aarlo
//
//  Created by martinhartl on 29.01.22.
//

import Foundation

final class PinboardClient: BookmarkClient {
    let pageSize = 20

    private var apiEndpoint: String {
        return "https://api.pinboard.in/v1"
    }

    let settingsStore: SettingsStore

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
    }

    func load(filteredByTags tags: [String]) async throws -> [Link] {
        guard var URL = URL(string: apiEndpoint + "/posts/all") else {
            throw ClientError.unknownURL
        }

        if !tags.isEmpty {
            URL = URL.appendingQueryParameters(["searchtags": tags.joined(separator: "+")])
        }

        URL = URL.appendingQueryParameters([
            "auth_token": settingsStore.secret.wrappedValue ?? "",
            "format": "json",
            "results": "20"
        ])

        var request = URLRequest(url: URL)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "GET"

        let (data, _) = try await URLSession.shared.data(for: request, delegate: nil)
        print(String(data: data, encoding: .utf8))
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let links = try decoder.decode([PinboardLink].self, from: data)

        // TODO: Convert
        return []
    }

    func loadMore(offset: Int, filteredByTags tags: [String]) async throws -> [Link] {
        []
    }

    func createLink(link: PostLink) async throws {
    }

    func updateLink(link: Link) async throws {
    }

    func deleteLink(link: Link) async throws {
    }

    func loadTags() async throws -> [Tag] {
        []
    }


}
