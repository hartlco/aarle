import SwiftUI
import Types

public struct UnreadSyncStatus: Sendable {
    public let isSyncing: Bool
    public let syncProgress: String
    public let totalCount: Int
    public let downloadedCount: Int
    public let failedCount: Int
    public let pendingCount: Int

    public init(
        isSyncing: Bool,
        syncProgress: String,
        totalCount: Int,
        downloadedCount: Int,
        failedCount: Int,
        pendingCount: Int
    ) {
        self.isSyncing = isSyncing
        self.syncProgress = syncProgress
        self.totalCount = totalCount
        self.downloadedCount = downloadedCount
        self.failedCount = failedCount
        self.pendingCount = pendingCount
    }
}

public struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @Bindable var settingsState: SettingsState
    var syncStatus: UnreadSyncStatus?
    var onClearAllDownloads: (() -> Void)?
    var onRetryAllFailed: (() async -> Void)?

    public init(
        settingsState: SettingsState,
        syncStatus: UnreadSyncStatus? = nil,
        onClearAllDownloads: (() -> Void)? = nil,
        onRetryAllFailed: (() async -> Void)? = nil
    ) {
        self.settingsState = settingsState
        self.syncStatus = syncStatus
        self.onClearAllDownloads = onClearAllDownloads
        self.onRetryAllFailed = onRetryAllFailed
    }

    public var body: some View {
        #if os(macOS)
            form
                .padding()
        #else
            NavigationView {
                form
            }
        #endif
    }

    var form: some View {
        // TODO: Add API endpoint info
        TabView {
            Form {
                Picker(
                    "Service",
                    selection: $settingsState.accountType
                ) {
                    ForEach(AccountType.allCases, id: \.self) {
                        Text($0.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                TextField(
                    "Key",
                    text: $settingsState.secret
                )
                .disableAutocorrection(true)
                if settingsState.accountType == .shaarli {
                    TextField(
                        "API Endpoint",
                        text: $settingsState.endpoint
                    )
                    .disableAutocorrection(true)
                    Text("Enter the endpoint in the following format: https://demo.shaarli.org/api/v1")
                        .font(.caption)
                }
                if settingsState.accountType == .linkding {
                    TextField(
                        "API Endpoint",
                        text: $settingsState.endpoint
                    )
                    .disableAutocorrection(true)
                    // TODO: Update link
                    Text("Enter the endpoint in the following format: https://demo.shaarli.org/api/v1")
                        .font(.caption)
                }
            }
            .tabItem {
                Label("Account", systemImage: "person.crop.circle")
            }
            Form {
                Section {
                    TextField(
                        "Metadata Endpoint (Optional)",
                        text: $settingsState.metadataEndpoint
                    )
                    .disableAutocorrection(true)
                    Text("Enter the base URL of your mscrap instance. If set, this will be used instead of native APIs to fetch website metadata including descriptions. Leave empty to use native iOS/macOS metadata fetching.")
                        .font(.caption)
                    Text("Requires mscrap service: https://github.com/hartlco/mscrap")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text("Metadata Fetching").font(.headline)
                }
                if settingsState.accountType == .linkding && !settingsState.metadataEndpoint.isEmpty {
                    Section {
                        Toggle("Auto-sync unread bookmarks", isOn: $settingsState.autoSyncUnread)
                        Text("Automatically download unread Linkding bookmarks for offline reading. Mark as read to remove them.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } header: {
                        Text("Unread Sync").font(.headline)
                    }
                    if let syncStatus {
                        Section {
                            if syncStatus.isSyncing {
                                HStack {
                                    ProgressView()
                                        .controlSize(.small)
                                    Text(syncStatus.syncProgress.isEmpty ? "Syncing..." : syncStatus.syncProgress)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            LabeledContent("Total items", value: "\(syncStatus.totalCount)")
                            LabeledContent("Downloaded", value: "\(syncStatus.downloadedCount)")
                            if syncStatus.failedCount > 0 {
                                LabeledContent("Failed", value: "\(syncStatus.failedCount)")
                                    .foregroundStyle(.orange)
                            }
                            if syncStatus.pendingCount > 0 {
                                LabeledContent("Pending", value: "\(syncStatus.pendingCount)")
                            }
                        } header: {
                            Text("Download Status").font(.headline)
                        }
                        Section {
                            if syncStatus.failedCount > 0 {
                                Button {
                                    Task {
                                        await onRetryAllFailed?()
                                    }
                                } label: {
                                    Label("Retry All Failed Downloads", systemImage: "arrow.clockwise")
                                }
                                .disabled(syncStatus.isSyncing)
                            }
                            Button(role: .destructive) {
                                onClearAllDownloads?()
                            } label: {
                                Label("Clear All Downloads", systemImage: "trash")
                            }
                            .disabled(syncStatus.isSyncing || syncStatus.totalCount == 0)
                        } header: {
                            Text("Manage Downloads").font(.headline)
                        }
                    }
                }
            }
            .tabItem {
                Label("Metadata", systemImage: "doc.text")
            }
            Form {
                Section {
                    Text("aarle is made by Martin Hartl, https://hartl.co")
                    Text("Open Source at https://github.com/hartlco/aarle")
                } header: {
                    Text("aarle").font(.headline)
                }
                Section {
                    Text("https://github.com/shaarli/Shaarli")
                } header: {
                    Text("Shaarli").font(.headline)
                }
            }
            .tabItem {
                Label("About", systemImage: "info.circle")
            }
        }
        .navigationTitle("Settings")
    }
}
