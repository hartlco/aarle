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
    @State var showsAddView = false
    @State var settingsField = ""
    @State var showingEditLink: Link?
    @Binding var selection: Link?

    @ObservedObject var linkStore: LinkStore

    private let pasteboard: Pasteboard
    private let title: String

    init(
        title: String,
        linkStore: LinkStore,
        pasteboard: Pasteboard = DefaultPasteboard(),
        linkSelection: Binding<Link?>
    ) {
        self.title = title
        self.linkStore = linkStore
        self.pasteboard = pasteboard
        self._selection = linkSelection
    }

    var body: some View {
        List(linkStore.links, id: \.self, selection: $selection) { link in
            NavigationLink {
                #if os(macOS)
                HSplitView {
                    WebView(data: WebViewData(url: link.url))
                    LinkEditView(link: link, linkStore: linkStore)
                        .frame(minWidth: 180, idealWidth: 400, maxWidth: 500)
                }
                #else
                WebView(data: WebViewData(url: link.url))
                #endif

            } label: {
                LinkItemView(link: link)
            }
            .contextMenu {
                Button("Edit", action: { showingEditLink = link })
                Button("Copy URL", action: { pasteboard.copyToPasteboard(string: link.url.absoluteString) })
                Button(role: .destructive) {
                    Task {
                        try await linkStore.delete(link: link)
                    }
                } label: {
                    Label("Delete", systemImage: "trash")
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
                        SettingsView()
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
            ToolbarItem(placement: bottomBarItemPlacement) {
                Button("Add") {
                    showsAddView = true
                }
                .sheet(
                    isPresented: $showsAddView,
                    onDismiss: nil,
                    content: {
                        LinkAddView(linkStore: linkStore)
                    }
                )
            }
        }
        .multiplatformNavigationBarTitle(title)
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

extension View {
    func multiplatformNavigationBarTitle(_ title: String) -> some View {
        #if os(iOS)
        self.navigationTitle(title)
        #elseif os(macOS)
        self
        #endif
    }
}
