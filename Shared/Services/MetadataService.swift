import Foundation
import LinkPresentation

struct WebsiteMetadata {
    let title: String?
    let description: String?
}

protocol MetadataServiceProtocol {
    func fetchMetadata(for url: URL) async throws -> WebsiteMetadata
}

final class MetadataService: MetadataServiceProtocol {
    private let customEndpoint: String?
    
    init(customEndpoint: String? = nil) {
        self.customEndpoint = customEndpoint?.isEmpty == false ? customEndpoint : nil
    }
    
    func fetchMetadata(for url: URL) async throws -> WebsiteMetadata {
        if let customEndpoint = customEndpoint {
            return try await fetchCustomMetadata(for: url, endpoint: customEndpoint)
        } else {
            return try await fetchNativeMetadata(for: url)
        }
    }
    
    private func fetchNativeMetadata(for url: URL) async throws -> WebsiteMetadata {
        return try await withCheckedThrowingContinuation { continuation in
            let provider = LPMetadataProvider()
            provider.startFetchingMetadata(for: url) { metadata, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let metadata = metadata else {
                    continuation.resume(returning: WebsiteMetadata(title: nil, description: nil))
                    return
                }
                
                continuation.resume(returning: WebsiteMetadata(
                    title: metadata.title,
                    description: nil // Native LinkPresentation doesn't provide description
                ))
            }
        }
    }
    
    private func fetchCustomMetadata(for url: URL, endpoint: String) async throws -> WebsiteMetadata {
        guard var endpointURL = URL(string: endpoint) else {
            throw MetadataError.invalidEndpoint
        }
        
        // Add the URL as a query parameter
        var components = URLComponents(url: endpointURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "url", value: url.absoluteString)]
        
        guard let requestURL = components?.url else {
            throw MetadataError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: requestURL)
        
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw MetadataError.networkError
        }
        
        let scrapResponse = try JSONDecoder().decode(MscrapResponse.self, from: data)
        
        return WebsiteMetadata(
            title: scrapResponse.title,
            description: scrapResponse.description
        )
    }
}

enum MetadataError: Error {
    case invalidEndpoint
    case invalidURL
    case networkError
    case decodingError
}

private struct MscrapResponse: Codable {
    let title: String?
    let description: String?
}