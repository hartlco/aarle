//
//  LinkdingClient.swift
//  Aarle
//
//  Created by Martin Hartl on 26.03.22.
//

import Foundation
import SwiftJWT
import Types

enum DateError: String, Error {
    case invalidDate
}

final class LinkdingClient: BookmarkClient {
    let pageSize = 100

    let keychain: AarleKeychain

    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    init(keychain: AarleKeychain) {
        self.keychain = keychain
    }

    func load(filteredByTags tags: [String] = [], searchTerm: String?) async throws -> [Link] {
        guard var URL = URL(string: apiEndpoint + "/api/bookmarks/") else {
            throw ClientError.unknownURL
        }

        var queryParameters: [String: String] = [:]
        queryParameters["q"] = searchStrings(from: tags, searchTerm: searchTerm).joined(separator: "+")
        URL = URL.appendingQueryParameters(queryParameters)

        var request = URLRequest(url: URL)
        request.httpMethod = "GET"

        request.addValue("Token " + keychain.secret, forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request, delegate: nil)
        let decoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        decoder.dateDecodingStrategy = .custom(date(from:))
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let result = try decoder.decode(LinkdingResult.self, from: data)

        return result.results.map(Link.fromLinkdingLink(link:))
    }

    func loadMore(offset: Int, filteredByTags tags: [String] = [], searchTerm: String?) async throws -> [Link] {
        guard var URL = URL(string: apiEndpoint + "/api/bookmarks/") else {
            throw ClientError.unknownURL
        }

        var queryParameters: [String: String] = [:]
        queryParameters["offset"] = String(offset)
        queryParameters["q"] = searchStrings(from: tags, searchTerm: searchTerm).joined(separator: "+")
        URL = URL.appendingQueryParameters(queryParameters)

        var request = URLRequest(url: URL)
        request.httpMethod = "GET"

        request.addValue("Token " + keychain.secret, forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request, delegate: nil)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom(date(from:))
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let result = try decoder.decode(LinkdingResult.self, from: data)
        return result.results.map(Link.fromLinkdingLink(link:))
    }

    func createLink(link: PostLink) async throws {
        guard let URL = URL(string: apiEndpoint + "/api/bookmarks/") else {
            throw ClientError.unknownURL
        }
        var request = URLRequest(url: URL)
        request.httpMethod = "POST"
        request.addValue("Token " + keychain.secret, forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let linkdingLink = LinkdingPostLink(
            url: link.url,
            title: link.title,
            description: link.description,
            tagNames: link.tags
        )

        let encoder = JSONEncoder()
        let linkData = try encoder.encode(linkdingLink)
        request.httpBody = linkData

        let (data, _) = try await URLSession.shared.data(for: request, delegate: nil)
    }

    func updateLink(link: Link) async throws {
        guard let URL = URL(string: "\(apiEndpoint + "/api/bookmarks")/\(link.id)/") else {
            throw ClientError.unknownURL
        }
        var request = URLRequest(url: URL)
        request.httpMethod = "PUT"
        request.addValue("Token " + keychain.secret, forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let postLink = LinkdingPostLink(
            url: link.url,
            title: link.title,
            description: link.description,
            tagNames: link.tags
        )

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let linkData = try encoder.encode(postLink)
        request.httpBody = linkData

        let (data, response) = try await URLSession.shared.data(for: request, delegate: nil)
    }

    func deleteLink(link: Link) async throws {
        guard let URL = URL(string: "\(apiEndpoint + "/api/bookmarks")/\(link.id)/") else {
            throw ClientError.unknownURL
        }
        var request = URLRequest(url: URL)
        request.httpMethod = "DELETE"
        request.addValue("Token " + keychain.secret, forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request, delegate: nil)
    }

    func loadTags() async throws -> [Tag] {
        // TODO: Increase tag limit
        guard let URL = URL(string: "\(apiEndpoint)/api/tags/") else {
            throw ClientError.unknownURL
        }

        var request = URLRequest(url: URL)
        request.httpMethod = "GET"
        request.addValue("Token " + keychain.secret, forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, _) = try await URLSession.shared.data(for: request, delegate: nil)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let tagResult = try decoder.decode(LinkdingTagResult.self, from: data)

        return tagResult.results
    }

    private var apiEndpoint: String {
        return keychain.endpoint
    }

    private func date(from decoder: Decoder) throws -> Date {
        let container = try decoder.singleValueContainer()
        let dateStr = try container.decode(String.self)

        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        if let date = formatter.date(from: dateStr) {
            return date
        }
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
        if let date = formatter.date(from: dateStr) {
            return date
        }
        throw DateError.invalidDate
    }

    private func searchStrings(from tags: [String], searchTerm: String?) -> [String] {
        let mappedTags = tags.map { "#\($0)" }

        if let searchTerm = searchTerm {
            return mappedTags + [searchTerm]
        }

        return mappedTags
    }
}
