import Foundation
import LinkPresentation

struct WebsiteMetadata {
    let title: String?
    let description: String?
}

protocol MetadataServiceProtocol {
    func fetchMetadata(for url: URL) async throws -> WebsiteMetadata
}

/// Service for fetching website metadata using either native LinkPresentation or a custom mscrap endpoint
///
/// For custom endpoint usage, provide the base URL of your mscrap instance (https://github.com/hartlco/mscrap).
/// The service will automatically append `/api/scrape` to the provided endpoint.
/// Example: If you provide "https://your-mscrap-instance.com", requests will be made to "https://your-mscrap-instance.com/api/scrape"
final class MetadataService: MetadataServiceProtocol {
    private let customEndpoint: String?
    
    /// Initialize MetadataService
    /// - Parameter customEndpoint: Base URL of your mscrap instance (https://github.com/hartlco/mscrap).
    ///   The `/api/scrape` route will be automatically appended.
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
        // Append /api/scrape to the base endpoint
        let fullEndpoint = endpoint.hasSuffix("/") ? "\(endpoint)api/scrape" : "\(endpoint)/api/scrape"
        
        guard let endpointURL = URL(string: fullEndpoint) else {
            throw MetadataError.invalidEndpoint
        }
        
        // Create POST request with JSON body
        var request = URLRequest(url: endpointURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create JSON body with URL
        let requestBody = ["url": url.absoluteString]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw MetadataError.encodingError
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
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
    case encodingError
}

private struct MscrapResponse: Codable {
    let title: String?
    let description: String?
}