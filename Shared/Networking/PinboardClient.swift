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

        var queryParams: [String: String] = [:]

        if !tags.isEmpty {
            queryParams["tag"] = tags.joined(separator: "+")
        }

        queryParams["auth_token"] = settingsStore.secret.wrappedValue ?? ""
        queryParams["format"] = "json"
        queryParams["results"] = "\(pageSize)"

        URL = URL.appendingQueryParameters(queryParams)

        var request = URLRequest(url: URL)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "GET"

        let (data, _) = try await URLSession.shared.data(for: request, delegate: nil)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let links = try decoder.decode([PinboardLink].self, from: data)

        return links.map(Link.fromPinboardLink(link:))
    }

    func loadMore(offset: Int, filteredByTags tags: [String]) async throws -> [Link] {
        guard var URL = URL(string: apiEndpoint + "/posts/all") else {
            throw ClientError.unknownURL
        }

        var queryParams: [String: String] = [:]

        if !tags.isEmpty {
            queryParams["tag"] = tags.joined(separator: "+")
        }

        queryParams["auth_token"] = settingsStore.secret.wrappedValue ?? ""
        queryParams["format"] = "json"
        queryParams["results"] = "\(pageSize)"
        queryParams["start"] = "\(offset)"

        URL = URL.appendingQueryParameters(queryParams)

        var request = URLRequest(url: URL)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "GET"

        let (data, _) = try await URLSession.shared.data(for: request, delegate: nil)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let links = try decoder.decode([PinboardLink].self, from: data)

        return links.map(Link.fromPinboardLink(link:))
    }

    func createLink(link: PostLink) async throws {
        guard var URL = URL(string: apiEndpoint + "/posts/add") else {
            throw ClientError.unknownURL
        }

        var queryParams: [String: String] = [:]

        queryParams["auth_token"] = settingsStore.secret.wrappedValue ?? ""
        queryParams["format"] = "json"
        queryParams["url"] = link.url.absoluteString
        queryParams["description"] = link.title ?? ""
        queryParams["extended"] = link.description
        queryParams["tags"] = link.tags.joined(separator: ",")

        URL = URL.appendingQueryParameters(queryParams)

        var request = URLRequest(url: URL)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "GET"

        let (data, _) = try await URLSession.shared.data(for: request, delegate: nil)
    }

    func updateLink(link: Link) async throws {
        try await createLink(link: PostLink(link: link))
    }

    func deleteLink(link: Link) async throws {
        guard var URL = URL(string: apiEndpoint + "/posts/delete") else {
            throw ClientError.unknownURL
        }

        var queryParams: [String: String] = [:]

        queryParams["auth_token"] = settingsStore.secret.wrappedValue ?? ""
        queryParams["format"] = "json"
        queryParams["url"] = link.url.absoluteString

        URL = URL.appendingQueryParameters(queryParams)

        var request = URLRequest(url: URL)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "GET"

        let (data, _) = try await URLSession.shared.data(for: request, delegate: nil)
    }

    func loadTags() async throws -> [Tag] {
        guard var URL = URL(string: apiEndpoint + "/tags/get") else {
            throw ClientError.unknownURL
        }

        var queryParams: [String: String] = [:]


        queryParams["auth_token"] = settingsStore.secret.wrappedValue ?? ""
        queryParams["format"] = "json"

        URL = URL.appendingQueryParameters(queryParams)

        var request = URLRequest(url: URL)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "GET"

        let (data, _) = try await URLSession.shared.data(for: request, delegate: nil)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let links = try decoder.decode([String: Int].self, from: data)

        return Tag.from(dictionary: links)
    }


}
