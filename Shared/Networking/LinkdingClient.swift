//
//  LinkdingClient.swift
//  Aarle
//
//  Created by Martin Hartl on 26.03.22.
//

import Foundation
import Types

enum DateError: String, Error {
  case invalidDate
}

@MainActor
final class LinkdingClient: BookmarkClient {
  let pageSize = 100

  let keychain: AarleKeychain

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
    let decoder = Self.makeLinkDecoder()
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
    let decoder = Self.makeLinkDecoder()
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
      tagNames: link.tags,
      unread: link.unread
    )

    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    let linkData = try encoder.encode(linkdingLink)
    request.httpBody = linkData

    let (_, _) = try await URLSession.shared.data(for: request, delegate: nil)
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
      tagNames: link.tags,
      unread: link.unread
    )

    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    let linkData = try encoder.encode(postLink)
    request.httpBody = linkData

    let (_, _) = try await URLSession.shared.data(for: request, delegate: nil)
  }

  func loadUnread() async throws -> [Link] {
    guard var URL = URL(string: apiEndpoint + "/api/bookmarks/") else {
      throw ClientError.unknownURL
    }

    var queryParameters: [String: String] = [:]
    queryParameters["q"] = "!unread"
    queryParameters["limit"] = String(pageSize)
    URL = URL.appendingQueryParameters(queryParameters)

    var request = URLRequest(url: URL)
    request.httpMethod = "GET"
    request.addValue("Token " + keychain.secret, forHTTPHeaderField: "Authorization")

    let (data, _) = try await URLSession.shared.data(for: request, delegate: nil)
    let decoder = Self.makeLinkDecoder()
    let result = try decoder.decode(LinkdingResult.self, from: data)
    return result.results.map(Link.fromLinkdingLink(link:))
  }

  func markAsRead(linkId: String) async throws {
    guard let URL = URL(string: "\(apiEndpoint)/api/bookmarks/\(linkId)/") else {
      throw ClientError.unknownURL
    }

    var request = URLRequest(url: URL)
    request.httpMethod = "PATCH"
    request.addValue("Token " + keychain.secret, forHTTPHeaderField: "Authorization")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONSerialization.data(withJSONObject: ["unread": false])

    let (_, _) = try await URLSession.shared.data(for: request, delegate: nil)
  }

  func markAsUnread(linkId: String) async throws {
    guard let URL = URL(string: "\(apiEndpoint)/api/bookmarks/\(linkId)/") else {
      throw ClientError.unknownURL
    }

    var request = URLRequest(url: URL)
    request.httpMethod = "PATCH"
    request.addValue("Token " + keychain.secret, forHTTPHeaderField: "Authorization")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONSerialization.data(withJSONObject: ["unread": true])

    let (_, _) = try await URLSession.shared.data(for: request, delegate: nil)
  }

  func deleteLink(link: Link) async throws {
    guard let URL = URL(string: "\(apiEndpoint + "/api/bookmarks")/\(link.id)/") else {
      throw ClientError.unknownURL
    }
    var request = URLRequest(url: URL)
    request.httpMethod = "DELETE"
    request.addValue("Token " + keychain.secret, forHTTPHeaderField: "Authorization")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")

    let (_, _) = try await URLSession.shared.data(for: request, delegate: nil)
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

  nonisolated private static func makeLinkDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    let dateDecoder: @Sendable (Decoder) throws -> Date = { decoder in
      try Self.date(from: decoder)
    }
    decoder.dateDecodingStrategy = .custom(dateDecoder)
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
  }

  nonisolated private static func date(from decoder: Decoder) throws -> Date {
    let container = try decoder.singleValueContainer()
    let dateStr = try container.decode(String.self)
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .iso8601)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)

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

// MARK: - URL Query Parameter Helpers

extension Dictionary: URLQueryParameterStringConvertible {
  var queryParameters: String {
    var parts: [String] = []
    for (key, value) in self {
      let part = String(
        format: "%@=%@",
        String(describing: key).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!,
        String(describing: value).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
      )
      parts.append(part as String)
    }
    return parts.joined(separator: "&")
  }
}

protocol URLQueryParameterStringConvertible {
  var queryParameters: String { get }
}

extension URL {
  func appendingQueryParameters(_ parametersDictionary: [String: String]) -> URL {
    let URLString = String(format: "%@?%@", absoluteString, parametersDictionary.queryParameters)
    return URL(string: URLString)!
  }
}
