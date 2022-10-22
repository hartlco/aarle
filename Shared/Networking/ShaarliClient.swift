//
//  ShaarliClient.swift
//  Aarlo
//
//  Created by martinhartl on 05.01.22.
//

import Foundation
import SwiftJWT
import Types

final class ShaarliClient: BookmarkClient {
    let pageSize = 20

    let keychain: AarleKeychain

    init(keychain: AarleKeychain) {
        self.keychain = keychain
    }

    func load(filteredByTags tags: [String] = [], searchTerm: String?) async throws -> [Link] {
        guard var URL = URL(string: apiEndpoint + "/links") else {
            throw ClientError.unknownURL
        }

        var queryParameters: [String: String] = [:]

        if !tags.isEmpty {
            queryParameters["searchtags"] = tags.joined(separator: "+")
        }

        if let searchTerm, !searchTerm.isEmpty {
            queryParameters["searchterm"] = searchTerm
        }

        URL = URL.appendingQueryParameters(queryParameters)

        var request = URLRequest(url: URL)
        request.httpMethod = "GET"
        let signedJWT = try signedJWT()

        request.addValue("Bearer " + signedJWT, forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request, delegate: nil)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let links = try decoder.decode([Link].self, from: data)

        return links
    }

    func loadMore(offset: Int, filteredByTags tags: [String] = [], searchTerm: String?) async throws -> [Link] {
        guard var URL = URL(string: apiEndpoint + "/links") else {
            throw ClientError.unknownURL
        }

        let signedJWT = try signedJWT()

        var queryParameters: [String: String] = [:]
        queryParameters["offset"] = String(offset)

        if !tags.isEmpty {
            queryParameters["searchtags"] = tags.joined(separator: "+")
        }

        if let searchTerm = searchTerm, !searchTerm.isEmpty {
            queryParameters["searchterm"] = searchTerm
        }

        URL = URL.appendingQueryParameters(queryParameters)

        var request = URLRequest(url: URL)
        request.httpMethod = "GET"

        request.addValue("Bearer " + signedJWT, forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request, delegate: nil)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let links = try decoder.decode([Link].self, from: data)
        print(String(data: data, encoding: .utf8))
        return links
    }

    func createLink(link: PostLink) async throws {
        let signedJWT = try signedJWT()

        guard let URL = URL(string: apiEndpoint + "/links") else {
            throw ClientError.unknownURL
        }
        var request = URLRequest(url: URL)
        request.httpMethod = "POST"
        request.addValue("Bearer " + signedJWT, forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let linkData = try JSONEncoder().encode(link)
        request.httpBody = linkData

        let (data, response) = try await URLSession.shared.data(for: request, delegate: nil)
        let dataString = String(data: data, encoding: .utf8)
        print(dataString)
    }

    func updateLink(link: Link) async throws {
        let signedJWT = try signedJWT()

        guard let URL = URL(string: "\(apiEndpoint + "/links")/\(link.id)") else {
            throw ClientError.unknownURL
        }
        var request = URLRequest(url: URL)
        request.httpMethod = "PUT"
        request.addValue("Bearer " + signedJWT, forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let postLink = PostLink(link: link)
        let linkData = try JSONEncoder().encode(postLink)
        request.httpBody = linkData

        let (data, response) = try await URLSession.shared.data(for: request, delegate: nil)
        let dataString = String(data: data, encoding: .utf8)
        print(dataString)
    }

    func deleteLink(link: Link) async throws {
        let signedJWT = try signedJWT()

        guard let URL = URL(string: "\(apiEndpoint + "/links")/\(link.id)") else {
            throw ClientError.unknownURL
        }
        var request = URLRequest(url: URL)
        request.httpMethod = "DELETE"
        request.addValue("Bearer " + signedJWT, forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, _) = try await URLSession.shared.data(for: request, delegate: nil)
        let dataString = String(data: data, encoding: .utf8)
        print(dataString)
    }

    func loadTags() async throws -> [Tag] {
        guard let URL = URL(string: "\(apiEndpoint)/tags") else {
            throw ClientError.unknownURL
        }

        var request = URLRequest(url: URL)
        request.httpMethod = "GET"
        let signedJWT = try signedJWT()

        request.addValue("Bearer " + signedJWT, forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request, delegate: nil)
        let dataString = String(data: data, encoding: .utf8)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let links = try decoder.decode([Tag].self, from: data)

        return links
    }

    private func signedJWT() throws -> String {
        let claims = ShaarliClaims(iat: .now.addingTimeInterval(-10.0))
        let header = SwiftJWT.Header(typ: "JWT")

        var jwt = SwiftJWT.JWT(header: header, claims: claims)

        let secret = keychain.secret
        let jwtSigner = JWTSigner.hs512(key: Data(secret.utf8))
        let signedJWT = try jwt.sign(using: jwtSigner)
        return signedJWT
    }

    private var apiEndpoint: String {
        return keychain.endpoint
    }
}

// PAW Helpers
protocol URLQueryParameterStringConvertible {
    var queryParameters: String { get }
}

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

extension URL {
    func appendingQueryParameters(_ parametersDictionary: [String: String]) -> URL {
        let URLString = String(format: "%@?%@", absoluteString, parametersDictionary.queryParameters)
        return URL(string: URLString)!
    }
}
