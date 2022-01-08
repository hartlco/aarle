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
    @State var showingEditLink: Link?
    @State var selection: Link?

    @ObservedObject var linkStore: LinkStore

    init(
        linkStore: LinkStore
    ) {
        self.linkStore = linkStore
    }

    var body: some View {
        List(linkStore.links, id: \.self, selection: $selection) { link in
            NavigationLink {
                #if os(macOS)
                HSplitView {
                    WebView(data: WebViewData(url: link.url))
                    LinkEditView(link: link, linkStore: linkStore)
                }
                #else
                WebView(data: WebViewData(url: link.url))
                #endif

            } label: {
                LinkItemView(link: link)
                    .contextMenu {
                            Button("Edit", action: { showingEditLink = link })
                    }
            }
        }
        .popover(item: $showingEditLink) { link in
            LinkEditView(link: link, linkStore: linkStore)
        }
        .toolbar {
            ToolbarItem(placement: navigationBarItemPlacement) {
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
            ToolbarItem(placement: navigationBarItemPlacement) {
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
            ToolbarItem(placement: bottomBarItemPlacement) {
                Button("Load More") {
                    Task {
                        do {
                            guard let lastLink = linkStore.links.last else { return }
                            try await linkStore.loadMoreIfNeeded(link: lastLink)
                        } catch {
                            print(error)
                        }
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

    private var navigationBarItemPlacement: ToolbarItemPlacement {
        #if os(macOS)
        return .automatic
        #else
        return .navigationBarTrailing
        #endif
    }

    private var bottomBarItemPlacement: ToolbarItemPlacement {
        #if os(macOS)
        return .automatic
        #else
        return .bottomBar
        #endif
    }
}
