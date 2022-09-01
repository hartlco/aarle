//
//  ItemDetailView.swift
//  Aarlo
//
//  Created by martinhartl on 12.01.22.
//

import SwiftUI
import SwiftUIX

struct ItemDetailView: View {
    let link: Link

    @EnvironmentObject var overallAppState: OverallAppState

    @State var shareSheetPresented = false

    init(
        link: Link
    ) {
        self.link = link
    }

    private let pasteboard = DefaultPasteboard()

    var body: some View {
        #if os(macOS)
            HSplitView {
                WebView(data: WebViewData(url: link.url))
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
                                overallAppState.showLinkEditorSidebar.toggle()
                            } label: {
                                Label("Show Edit Link", systemImage: "sidebar.right")
                            }
                        }
                    }
                if overallAppState.showLinkEditorSidebar {
                    LinkEditView(link: link, showCancelButton: false)
                        .frame(minWidth: 220, idealWidth: 400, maxWidth: 500)
                }
            }
        #else
            WebView(data: WebViewData(url: link.url))
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink {
                            LinkEditView(link: link, showCancelButton: false)
                        } label: {
                            Label("Edit", systemImage: "pencil.circle")
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            shareSheetPresented = true
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }.sheet(isPresented: $shareSheetPresented) {
                            AppActivityView(activityItems: [link.url], applicationActivities: nil)
                        }

                        NavigationLink {
                            LinkEditView(link: link, showCancelButton: false)
                        } label: {
                            Label("Edit", systemImage: "pencil.circle")
                        }
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle(link.title ?? "")
        #endif
    }
}
