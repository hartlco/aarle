//
//  ShareViewController.swift
//  Aarlo-iOS-ShareExtension
//
//  Created by martinhartl on 22.01.22.
//

import KeychainAccess
import Social
import SwiftUI
import UIKit
import Tag

final class ShareViewController: UIViewController {
    static let keyChain = Keychain(service: "co.hartl.Aarle")
    
    required init?(coder: NSCoder) {
      super.init(coder: coder)
    }
    
    let overallAppState = OverallAppState(
        client: UniversalClient(keychain: keyChain),
        keychain: keyChain
    )

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let inputItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            // TODO: Show error
            return
        }

        Task {
            var title: String?
            var description: String?
            var urlString: String?

            for item in inputItems {
                for attachment in item.attachments ?? [] {
                    let websiteInformation = try? await attachment.loadWebsiteInformation()
                    title = websiteInformation?.title ?? title
                    description = websiteInformation?.description ?? description
                    urlString = websiteInformation?.baseURI ?? urlString

                    let loadedURL = try? await attachment.loadURL()
                    urlString = loadedURL?.absoluteString ?? urlString
                }
            }

            self.showView(for: urlString, title: title, description: description)
        }
    }

    @MainActor
    private func showView(for urlString: String?, title: String?, description: String?) {
      overallAppState.addState.urlString = urlString ?? ""
      overallAppState.addState.title = title ?? ""
      overallAppState.addState.description = description ?? ""
      overallAppState.addState.onSaveComplete = { [weak self] in
        self?.send(self)
      }

      Task { await overallAppState.tagState.load() }
      Task { await checkReachability() }

      if let urlString, !urlString.isEmpty,
         (title ?? "").isEmpty, (description ?? "").isEmpty {
        Task { await fetchMetadata(for: urlString) }
      } else {
        Task { await checkMetadataReachability() }
      }

        let addView = LinkAddView(
            overallAppState: overallAppState,
            onCancel: { [weak self] in
              self?.cancel(self)
            }
        )

        let hosting = UIHostingController(rootView: addView)
        addChild(hosting)
        view.addSubview(hosting.view)
        hosting.didMove(toParent: self)

        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor)
        ])
    }

    @MainActor
    private func fetchMetadata(for urlString: String) async {
      guard let url = URL(string: urlString) else { return }
      overallAppState.addState.isLoadingMetadata = true
      let metadataService = MetadataService(customEndpoint: overallAppState.settingsState.metadataEndpoint)
      do {
        let metadata = try await metadataService.fetchMetadata(for: url)
        if overallAppState.addState.title.isEmpty, let title = metadata.title {
          overallAppState.addState.title = title
        }
        if overallAppState.addState.description.isEmpty, let description = metadata.description {
          overallAppState.addState.description = description
        }
        overallAppState.addState.metadataReachability = .reachable
      } catch {
        overallAppState.addState.metadataReachability = .unreachable
      }
      overallAppState.addState.isLoadingMetadata = false
    }

    @MainActor
    private func checkReachability() async {
      overallAppState.addState.linkdingReachability = .checking
      let endpoint = overallAppState.settingsState.endpoint
      let secret = overallAppState.settingsState.secret
      guard !endpoint.isEmpty, !secret.isEmpty,
            let url = URL(string: "\(endpoint)/api/tags/") else {
        overallAppState.addState.linkdingReachability = .unreachable
        return
      }
      var request = URLRequest(url: url)
      request.httpMethod = "GET"
      request.addValue("Token \(secret)", forHTTPHeaderField: "Authorization")
      request.timeoutInterval = 5
      do {
        let (_, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, 200...299 ~= http.statusCode {
          overallAppState.addState.linkdingReachability = .reachable
        } else {
          overallAppState.addState.linkdingReachability = .unreachable
        }
      } catch {
        overallAppState.addState.linkdingReachability = .unreachable
      }
    }

    @MainActor
    private func checkMetadataReachability() async {
      let metadataEndpoint = overallAppState.settingsState.metadataEndpoint
      guard !metadataEndpoint.isEmpty, let checkURL = URL(string: metadataEndpoint) else { return }
      overallAppState.addState.metadataReachability = .checking
      var req = URLRequest(url: checkURL)
      req.httpMethod = "HEAD"
      req.timeoutInterval = 5
      do {
        let (_, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode < 500 {
          overallAppState.addState.metadataReachability = .reachable
        } else {
          overallAppState.addState.metadataReachability = .unreachable
        }
      } catch {
        overallAppState.addState.metadataReachability = .unreachable
      }
    }

    @IBAction func send(_: AnyObject?) {
        let outputItem = NSExtensionItem()
        // Complete implementation by setting the appropriate value on the output item

        let outputItems = [outputItem]
        extensionContext!.completeRequest(returningItems: outputItems, completionHandler: nil)
    }

    @IBAction func cancel(_: AnyObject?) {
        let cancelError = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil)
        extensionContext!.cancelRequest(withError: cancelError)
    }
}
