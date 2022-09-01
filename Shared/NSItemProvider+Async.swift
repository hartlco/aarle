//
//  NSItemProvider+Async.swift
//  Aarlo
//
//  Created by martinhartl on 22.01.22.
//

import Foundation

#if os(iOS)
    import MobileCoreServices
#elseif os(macOS)
    import Cocoa
#endif

extension NSItemProvider {
    enum ProviderError: Error {
        case dataNotConvertible
    }

    func loadWebsiteInformation() async throws -> WebsiteInformation {
        try await withCheckedThrowingContinuation { continuation in
            loadItem(
                forTypeIdentifier: String(kUTTypePropertyList),
                options: nil
            ) { coding, error in
                if let error = error {
                    return continuation.resume(throwing: error)
                }

                if let coding = coding as? NSDictionary,
                   let model = WebsiteInformation(fromJavaScriptPreprocessing: coding)
                {
                    print(coding)
                    return continuation.resume(returning: model)
                }

                return continuation.resume(throwing: ProviderError.dataNotConvertible)
            }
        }
    }

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
