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

    @Bindable var overallAppState: OverallAppState
    @StateObject private var webViewData: WebViewData

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State var shareSheetPresented = false
    @State private var isLoadingReadable = false
    @State private var isUnread: Bool

    init(
        link: Types.Link,
        overallAppState: OverallAppState
    ) {
        self.link = link
        self.overallAppState = overallAppState
        self._webViewData = StateObject(wrappedValue: WebViewData(url: nil))
        self._isUnread = State(initialValue: link.unread)
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

                    Button(action: {
                        Task { await handleReadableArticleTap() }
                    }) {
                        Image(systemName: "doc.richtext")
                            .foregroundColor(readableArchiveLink() != nil ? .accentColor : .primary)
                            .overlay {
                                if isLoadingReadable {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .scaleEffect(0.6)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoadingReadable)
                    .help("Show Readable Article")
                    
                    Button(action: {
                        NSWorkspace.shared.open(link.url)
                    }) {
                        Image(systemName: "safari")
                            .foregroundColor(.primary)
                    }
                    .help("Open in Safari")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor))
                .frame(minHeight: 32)
            }
        }
        .toolbar {
            ToolbarItem {
                Button {
                    Task {
                        if isUnread {
                            await overallAppState.markLinkAsRead(link: link)
                        } else {
                            await overallAppState.markLinkAsUnread(link: link)
                        }
                        isUnread.toggle()
                    }
                } label: {
                    Label(
                        isUnread ? "Mark as Read" : "Mark as Unread",
                        systemImage: isUnread ? "checkmark.circle" : "circle"
                    )
                }
            }
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
            HStack(spacing: 0) {
                Button(action: {
                    webViewData.goBack()
                }) {
                    Image(systemName: "chevron.backward")
                        .font(.system(size: 18))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .disabled(!webViewData.canGoBack)

                Button(action: {
                    webViewData.goForward()
                }) {
                    Image(systemName: "chevron.forward")
                        .font(.system(size: 18))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .disabled(!webViewData.canGoForward)

                Spacer()

                Button(action: {
                    Task { await handleReadableArticleTap() }
                }) {
                    Image(systemName: "doc.richtext")
                        .font(.system(size: 18))
                        .foregroundColor(readableArchiveLink() != nil ? .accentColor : nil)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .contentShape(Rectangle())
                        .overlay {
                            if isLoadingReadable {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(0.7)
                            }
                        }
                }
                .disabled(isLoadingReadable)

                Button(action: {
                    UIApplication.shared.open(link.url)
                }) {
                    Image(systemName: "safari")
                        .font(.system(size: 18))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .contentShape(Rectangle())
                }
            }
            .background(Color(UIColor.secondarySystemBackground))
        }
        .toolbar {
            if horizontalSizeClass == .regular {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        withAnimation {
                            if overallAppState.navigationState.columnVisibility == .detailOnly {
                                overallAppState.navigationState.columnVisibility = .automatic
                            } else {
                                overallAppState.navigationState.columnVisibility = .detailOnly
                            }
                        }
                    } label: {
                        Label(
                            overallAppState.navigationState.columnVisibility == .detailOnly ? "Show Sidebar" : "Full Width",
                            systemImage: overallAppState.navigationState.columnVisibility == .detailOnly ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right"
                        )
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task {
                        if isUnread {
                            await overallAppState.markLinkAsRead(link: link)
                        } else {
                            await overallAppState.markLinkAsUnread(link: link)
                        }
                        isUnread.toggle()
                    }
                } label: {
                    Label(
                        isUnread ? "Mark as Read" : "Mark as Unread",
                        systemImage: isUnread ? "checkmark.circle" : "circle"
                    )
                }
            }
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

    private func readableArchiveLink() -> ArchiveLink? {
        if let archiveLink = overallAppState.archiveState.archiveLinks.first(where: { $0.originalLinkId == link.id }) {
            return archiveLink
        }

        return overallAppState.archiveState.archiveLinks.first(where: { $0.url == link.url })
    }

    @MainActor
    private func handleReadableArticleTap() async {
        if let archiveLink = readableArchiveLink() {
            openReadableArchiveLink(archiveLink)
            return
        }

        guard isLoadingReadable == false else { return }

        isLoadingReadable = true
        defer { isLoadingReadable = false }

        await overallAppState.archiveState.archiveLink(link: link)

        if let archiveLink = readableArchiveLink() {
            openReadableArchiveLink(archiveLink)
        }
    }

    @MainActor
    private func openReadableArchiveLink(_ archiveLink: ArchiveLink) {
        let destination = DetailNavigationDestination.archiveLink(archiveLink)
        if overallAppState.navigationState.detailNavigationStack.contains(destination) == false {
            overallAppState.navigationState.detailNavigationStack.append(destination)
        }
    }
}
