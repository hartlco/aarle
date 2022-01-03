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

    var body: some View {
        List(links) { link in
            LinkItemView(link: link)
        }
        .toolbar {
            Button("Load") {
                Task {
                    do {
                        try await load()
                    } catch let error {
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
                print(error)
            }
        }
    }

    private func load() async throws {
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
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
