//
//  ContentView.swift
//  Shared
//
//  Created by martinhartl on 02.01.22.
//

import SwiftUI
import SwiftJWT
import SwiftUIX
import WebKit

struct ContentView: View {
    @State var showsSettings = false
    @State var settingsField = ""

    @ObservedObject var linkStore: LinkStore

    init(linkStore: LinkStore) {
        self.linkStore = linkStore
    }

    var body: some View {
        List(linkStore.links) { link in
            NavigationLink {
                LinkEditView(link: link, linkStore: linkStore)
            } label: {
                LinkItemView(link: link)
                    .onAppear {
                        Task {
                            do {
                                try await linkStore.loadMoreIfNeeded(link: link)
                            } catch let error {
                                print(error)
                            }
                        }
                    }
            }
        }
        .toolbar {
            ToolbarItem(placement: itemPlacement) {
                Button("Load") {
                    Task {
                        do {
                            try await linkStore.load()
                        } catch let error {
                            print(error)
                        }
                    }
                }
            }
            ToolbarItem(placement: itemPlacement) {
                Button("Settings") {
                    showsSettings = true
                }
                .sheet(
                    isPresented: $showsSettings,
                    onDismiss: nil,
                    content: {
                        SettingsView(showsSettings: $showsSettings)
                    }
                )
            }
            ToolbarItem(placement: itemPlacement) {
                Button("Add") {
                    Task {
                        let link = PostLink(
                            url: URL(string: "https://hartl.co")!,
                            title: "hartl.co",
                            description: "my site",
                            tags: [],
                            private: false,
                            created: Date.now
                        )

                        try await linkStore.add(link: link)
                    }
                }
            }
        }
        .task {
            do {
                try await linkStore.load()
            } catch let error {
                print(error)
            }
        }
    }

    private var itemPlacement: ToolbarItemPlacement {
        #if os(macOS)
        return .automatic
        #else
        return .navigationBarTrailing
        #endif
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
