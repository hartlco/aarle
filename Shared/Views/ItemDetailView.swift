//
//  ItemDetailView.swift
//  Aarlo
//
//  Created by martinhartl on 12.01.22.
//

import SwiftUI

struct ItemDetailView: View {
    let link: Link
    let linkStore: LinkStore

    private let pasteboard = DefaultPasteboard()

    var body: some View {
#if os(macOS)
        HSplitView {
            WebView(data: WebViewData(url: link.url))
            LinkEditView(link: link, linkStore: linkStore)
                .frame(minWidth: 180, idealWidth: 400, maxWidth: 500)
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
        ItemDetailView(link: Link.mock, linkStore: LinkStore.mock)
    }
}
#endif
