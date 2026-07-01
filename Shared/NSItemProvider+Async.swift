//
//  NSItemProvider+Async.swift
//  Aarlo
//
//  Created by martinhartl on 22.01.22.
//

import Foundation
import Types
import UniformTypeIdentifiers

#if os(macOS)
    import Cocoa
#endif

extension NSItemProvider {
    enum ProviderError: Error {
        case dataNotConvertible
    }

    @MainActor
    func loadWebsiteInformation() async throws -> WebsiteInformation {
        let typeIdentifier = UTType.propertyList.identifier
        guard hasItemConformingToTypeIdentifier(typeIdentifier) else {
            throw ProviderError.dataNotConvertible
        }

        return try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<WebsiteInformation, any Error>) in
            loadDataRepresentation(forTypeIdentifier: typeIdentifier) { (data: Data?, error: (any Error)?) in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let data else {
                    continuation.resume(throwing: ProviderError.dataNotConvertible)
                    return
                }

                do {
                    let propertyList = try PropertyListSerialization.propertyList(
                        from: data,
                        options: [],
                        format: nil
                    )
                    if let coding = propertyList as? NSDictionary,
                       let model = WebsiteInformation(fromJavaScriptPreprocessing: coding)
                    {
                        continuation.resume(returning: model)
                        return
                    }
                } catch {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(throwing: ProviderError.dataNotConvertible)
            }
        }
    }

    @MainActor
    func loadURL() async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            guard canLoadObject(ofClass: URL.self) else {
                return continuation.resume(throwing: ProviderError.dataNotConvertible)
            }

            _ = loadObject(ofClass: URL.self) { url, error in
                if let error = error {
                    return continuation.resume(throwing: error)
                }

                if let url = url {
                    return continuation.resume(returning: url)
                }

                return continuation.resume(throwing: ProviderError.dataNotConvertible)
            }
        }
    }
}
