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
    @StateObject private var webViewData: WebViewData

    @State var shareSheetPresented = false

    init(
        link: Types.Link,
        overallAppState: OverallAppState
    ) {
        self.link = link
        self.overallAppState = overallAppState
        self._webViewData = StateObject(wrappedValue: WebViewData(url: nil))
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
                    .id(webViewData.webViewId)
                    .onAppear {
                        webViewData.url = link.url
                    }
                    .onChange(of: link.url) { newURL in
                        // Clear navigation history when loading a new link
                        webViewData.clearNavigationHistory()
                        webViewData.url = newURL
                    }
                HStack(spacing: 12) {
                    Button(action: {
                        webViewData.goBack()
                    }) {
                        Image(systemName: "chevron.backward")
                            .foregroundColor(webViewData.canGoBack ? .primary : .secondary)
                    }
                    .disabled(!webViewData.canGoBack)
                    .help("Go Back")
                    
                    Button(action: {
                        webViewData.goForward()
                    }) {
                        Image(systemName: "chevron.forward")
                            .foregroundColor(webViewData.canGoForward ? .primary : .secondary)
                    }
                    .disabled(!webViewData.canGoForward)
                    .help("Go Forward")
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor))
                .frame(minHeight: 32)
            }
        }
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
#else
        VStack(spacing: 0) {
            if webViewData.progress > 0, webViewData.progress < 1 {
                ProgressView(value: webViewData.progress)
                    .progressViewStyle(LinearProgressViewStyle())
            }
            WebView(data: webViewData)
                .id(webViewData.webViewId)
                .onAppear {
                    webViewData.url = link.url
                }
                .onChange(of: link.url) { newURL in
                    // Clear navigation history when loading a new link
                    webViewData.clearNavigationHistory()
                    webViewData.url = newURL
                }
            HStack(spacing: 12) {
                Button(action: {
                    webViewData.goBack()
                }) {
                    Image(systemName: "chevron.backward")
                        .foregroundColor(webViewData.canGoBack ? .primary : .secondary)
                }
                .disabled(!webViewData.canGoBack)
                
                Button(action: {
                    webViewData.goForward()
                }) {
                    Image(systemName: "chevron.forward")
                        .foregroundColor(webViewData.canGoForward ? .primary : .secondary)
                }
                .disabled(!webViewData.canGoForward)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(UIColor.systemBackground))
            .frame(minHeight: 32)
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
