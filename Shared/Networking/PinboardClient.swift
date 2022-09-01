//
//  PinboardClient.swift
//  Aarlo
//
//  Created by martinhartl on 29.01.22.
//

import Foundation
import Types

final class PinboardClient: BookmarkClient {
    let pageSize = 20

    private var apiEndpoint: String {
        return "https://api.pinboard.in/v1"
    }

    let keychain: AarleKeychain

    init(keychain: AarleKeychain) {
        self.keychain = keychain
    }

    func load(filteredByTags tags: [String], searchTerm: String?) async throws -> [Link] {
        if let searchTerm = searchTerm, !searchTerm.isEmpty {
            return try await search(filteredByTags: tags, searchTerm: searchTerm)
        }

        guard var URL = URL(string: apiEndpoint + "/posts/all") else {
            throw ClientError.unknownURL
        }

        var queryParams: [String: String] = [:]

        if !tags.isEmpty {
            queryParams["tag"] = tags.joined(separator: "+")
        }

        queryParams["auth_token"] = keychain.secret
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

    private func search(filteredByTags tags: [String], searchTerm: String) async throws -> [Link] {
        guard var URL = URL(string: apiEndpoint + "/posts/all") else {
            throw ClientError.unknownURL
        }

        var queryParams: [String: String] = [:]

        if !tags.isEmpty {
            queryParams["tag"] = tags.joined(separator: "+")
        }

        queryParams["auth_token"] = keychain.secret
        queryParams["format"] = "json"
        queryParams["results"] = "\(1000)"

        URL = URL.appendingQueryParameters(queryParams)

        var request = URLRequest(url: URL)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "GET"

        let (data, _) = try await URLSession.shared.data(for: request, delegate: nil)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let links = try decoder.decode([PinboardLink].self, from: data)

        return links.filter { link in
            if let description = link.description, description.lowercased().contains(searchTerm.lowercased()) {
                return true
            }

            if let extended = link.extended, extended.lowercased().contains(searchTerm.lowercased()) {
                return true
            }

            if link.href.lowercased().contains(searchTerm.lowercased()) {
                return true
            }

            return false
        }.map(Link.fromPinboardLink(link:))
    }

    func loadMore(offset: Int, filteredByTags tags: [String], searchTerm _: String?) async throws -> [Link] {
        guard var URL = URL(string: apiEndpoint + "/posts/all") else {
            throw ClientError.unknownURL
        }

        var queryParams: [String: String] = [:]

        if !tags.isEmpty {
            queryParams["tag"] = tags.joined(separator: "+")
        }

        queryParams["auth_token"] = keychain.secret
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

        queryParams["auth_token"] = keychain.secret
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

        queryParams["auth_token"] = keychain.secret
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

        queryParams["auth_token"] = keychain.secret
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
