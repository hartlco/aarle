//
//  ContentView.swift
//  Shared
//
//  Created by martinhartl on 02.01.22.
//

import SwiftUI
import SwiftJWT

struct ContentView: View {
    @State var links: [Link] = []
    @State var showsSettings = false
    @State var settingsField = ""

    @State var isLoading = false

    var body: some View {
        List(links) { link in
            LinkItemView(link: link)
                .onAppear {
                    Task {
                        do {
                            try await loadMoreIfNeeded(link: link)
                        } catch let error {
                            isLoading = false
                            print(error)
                        }
                    }
                }
        }
        .toolbar {
            Button("Load") {
                Task {
                    do {
                        try await load()
                    } catch let error {
                        isLoading = false
                        print(error)
                    }
                }
            }
            Button("Settings") {
                showsSettings = true
            }
            .sheet(isPresented: $showsSettings, onDismiss: nil, content: {
                SettingsView(showsSettings: $showsSettings)
            })
        }
        .task {
            do {
                try await load()
            } catch let error {
                isLoading = false
                print(error)
            }
        }
    }

    private func load() async throws {
        guard isLoading == false else { return }

        isLoading = true

        let claims = ShaarliClaims(iat: .now.addingTimeInterval(-10.0))
        let header = SwiftJWT.Header(typ: "JWT")

        var jwt = SwiftJWT.JWT(header: header, claims: claims)

        let secret = SettingsView.keychain[string: SettingsView.keychainKey] ?? ""
        let jwtSigner = JWTSigner.hs512(key: Data(secret.utf8))
        let signedJWT = try jwt.sign(using: jwtSigner)

        guard let URL = URL(string: "https://hartlco.uber.space/shaarli/index.php/api/v1/links") else { return }
        var request = URLRequest(url: URL)
        request.httpMethod = "GET"

        request.addValue("Bearer " + signedJWT, forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request, delegate: nil)
        let links = try JSONDecoder().decode([Link].self, from: data)

        // TODO: Catch Unauthorized

        self.links = links

        isLoading = false
    }

    private func loadMoreIfNeeded(link: Link) async throws {
        guard isLoading == false else { return }

        guard var URL = URL(string: "https://hartlco.uber.space/shaarli/index.php/api/v1/links"),
              link.id == links.last?.id else { return }

        isLoading = true

        let claims = ShaarliClaims(iat: .now.addingTimeInterval(-10.0))
        let header = SwiftJWT.Header(typ: "JWT")

        var jwt = SwiftJWT.JWT(header: header, claims: claims)

        let secret = SettingsView.keychain[string: SettingsView.keychainKey] ?? ""
        let jwtSigner = JWTSigner.hs512(key: Data(secret.utf8))
        let signedJWT = try jwt.sign(using: jwtSigner)

        URL = URL.appendingQueryParameters(["offset": "\(links.count)"])

        var request = URLRequest(url: URL)
        request.httpMethod = "GET"

        request.addValue("Bearer " + signedJWT, forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request, delegate: nil)
        let links = try JSONDecoder().decode([Link].self, from: data)

        // TODO: Catch Unauthorized

        self.links.append(contentsOf: links)

        isLoading = false
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

// PAW Helpers
protocol URLQueryParameterStringConvertible {
    var queryParameters: String {get}
}

extension Dictionary : URLQueryParameterStringConvertible {
    var queryParameters: String {
        var parts: [String] = []
        for (key, value) in self {
            let part = String(format: "%@=%@",
                String(describing: key).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!,
                String(describing: value).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)
            parts.append(part as String)
        }
        return parts.joined(separator: "&")
    }

}

extension URL {
    func appendingQueryParameters(_ parametersDictionary : Dictionary<String, String>) -> URL {
        let URLString : String = String(format: "%@?%@", self.absoluteString, parametersDictionary.queryParameters)
        return URL(string: URLString)!
    }
}
