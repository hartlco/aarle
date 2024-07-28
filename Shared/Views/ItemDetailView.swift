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
                            Menu {
                                ForEach(NSSharingService.sharingServices(forItems: [link.url]), id: \.title) { service in
                                    Button(action: { service.perform(withItems: [link.url]) }) {
                                        Image(nsImage: service.image)
                                        Text(service.title)
                                    }
                                }
                            } label: {
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
            if overallAppState.navigationState.showLinkEditorSidebar {
                LinkEditView(
                    overallAppState: overallAppState,
                    link: link,
                    showCancelButton: false
                )
                .frame(minWidth: 220, idealWidth: 400, maxWidth: 500)
            }
        }
#else
        WebView(data: WebViewData(url: link.url))
        //                .toolbar {
        //                    ToolbarItem(placement: .navigationBarTrailing) {
        //                        NavigationLink {
        //                            LinkEditView(overallAppState: overallAppState, link: link, showCancelButton: false)
        //                        } label: {
        //                            Label("Edit", systemImage: "pencil.circle")
        //                        }
        //                    }
        //                    ToolbarItem(placement: .navigationBarTrailing) {
        //                        Button {
        //                            shareSheetPresented = true
        //                        } label: {
        //                            Label("Share", systemImage: "square.and.arrow.up")
        //                        }.sheet(isPresented: $shareSheetPresented) {
        //                            AppActivityView(activityItems: [link.url], applicationActivities: nil)
        //                        }
        //
        //                        NavigationLink {
        //                            LinkEditView(link: link, showCancelButton: false)
        //                        } label: {
        //                            Label("Edit", systemImage: "pencil.circle")
        //                        }
        //                    }
        //                }
        //                .navigationBarTitleDisplayMode(.inline)
        //                .navigationTitle(link.title ?? "")
#endif
    }
}
