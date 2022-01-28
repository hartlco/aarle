//
//  ItemDetailView.swift
//  Aarlo
//
//  Created by martinhartl on 12.01.22.
//

import SwiftUI

struct ItemDetailView: View {
    let link: Link
    @ObservedObject private var linkStore: LinkStore

    @EnvironmentObject var tagStore: TagStore
    @EnvironmentObject var appStore: AppStore

    init(
        link: Link,
        linkStore: LinkStore
    ) {
        self.link = link
        self.linkStore = linkStore
    }

    private let pasteboard = DefaultPasteboard()

    var body: some View {
#if os(macOS)
        HSplitView {
            WebView(data: WebViewData(url: link.url))
                .toolbar {
                    Spacer()
                    Button {
                        if appStore.showLinkEditorSidebar {
                            appStore.reduce(.hideLinkEditorSidebar)
                        } else {
                            appStore.reduce(.showLinkEditorSidebar)
                        }
                    } label: {
                        Label("Show Edit Link", systemImage: "sidebar.right")
                    }
                    // TODO: Add keyboard shortcut

                }
            if appStore.showLinkEditorSidebar {
                LinkEditView(link: link, linkStore: linkStore)
                    .frame(minWidth: 220, idealWidth: 400, maxWidth: 500)
            }
        }
#else
        WebView(data: WebViewData(url: link.url))
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button(action: {
                        UIApplication.shared.open(
                            link.url,
                            options: [:],
                            completionHandler: nil
                        )
                    }, label: {
                        Label("Open in Safari ", systemImage: "safari")
                    })
                }
                // TODO: Show share sheet instead
                ToolbarItem(placement: .bottomBar) {
                    Button(action: {
                        pasteboard.copyToPasteboard(string: link.url.absoluteString)
                    }, label: {
                        Label("Copy to Clipboard ", systemImage: "paperclip.circle")
                    })
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        LinkEditView(link: link, linkStore: linkStore)
                    } label: {
                        Label("Edit", systemImage: "pencil.circle")
                    }

                }
            }
            .navigationTitle(link.title ?? "")
#endif
    }
}

#if DEBUG
struct ItemDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ItemDetailView(
            link: Link.mock,
            linkStore: LinkStore.mock
        ).environmentObject(TagStore.mock)
    }
}
#endif
