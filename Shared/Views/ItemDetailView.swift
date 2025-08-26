//
//  ItemDetailView.swift
//  Aarlo
//
//  Created by martinhartl on 12.01.22.
//

import SwiftUI
import Types
import Navigation

struct ItemDetailView: View {
    let link: Types.Link

    var overallAppState: OverallAppState
    @ObservedObject var webViewData: WebViewData

    @State var shareSheetPresented = false

    init(
        link: Types.Link,
        overallAppState: OverallAppState
    ) {
        self.link = link
        self.overallAppState = overallAppState
        self.webViewData = WebViewData(url: link.url)
    }

    private let pasteboard = DefaultPasteboard()

    var body: some View {
#if os(macOS)
        HSplitView {
            VStack(spacing: 0) {
                if webViewData.progress > 0, webViewData.progress < 1 {
                    ProgressView(value: webViewData.progress)
                        .progressViewStyle(MinimalProgressViewStyle())
                }
                WebView(data: webViewData)
                    .toolbar {
                        ToolbarItem {
                            ShareLink(item: link.url) {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                        }
                        ToolbarItem {
                            Button {
                                overallAppState.navigationState.showLinkEditorSidebar.toggle()
                            } label: {
                                Label("Show Edit Link", systemImage: "sidebar.right")
                            }
                        }
                    }
            }
        }
#else
        VStack(spacing: 0) {
            if webViewData.progress > 0, webViewData.progress < 1 {
                ProgressView(value: webViewData.progress)
                    .progressViewStyle(LinearProgressViewStyle())
            }
            WebView(data: webViewData)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                ShareLink(item: link.url) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    overallAppState.navigationState.presentedEditLink = link
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(link.title ?? "")
#endif
    }
}
