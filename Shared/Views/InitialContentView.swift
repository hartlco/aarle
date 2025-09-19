//
//  InitialContentView.swift
//  Aarlo
//
//  Created by martinhartl on 12.01.22.
//

import SwiftUI
import Types
import Settings
import Navigation
import Tag
import Archive

struct InitialContentView: View {
  @State private var preferredCompactColumn = NavigationSplitViewColumn.sidebar
  @Environment(OverallAppState.self) private var overallAppState

  var body: some View {
    @Bindable var overallAppState = overallAppState
    NavigationSplitView(
      preferredCompactColumn: $preferredCompactColumn
    ) {
      SidebarView()
        .navigationTitle("aarle")
        .alert(isPresented: $overallAppState.listState.showLoadingError) {
          networkingAlert
        }
        .alert(
          isPresented: $overallAppState.tagState.showLoadingError
        ) {
          networkingAlert
        }
    } content: {
      switch overallAppState.navigationState.selectedListType {
      case .all:
        ContentView(
          title: "Links",
          listType: .all,
          presentationMode: .list,
          navigationState: overallAppState.navigationState,
          listState: overallAppState.listState,
          archiveState: overallAppState.archiveState,
          overallAppState: overallAppState
        )
      case let .tagScoped(tag):
        ContentView(
          title: tag.name,
          listType: .tagScoped(tag),
          presentationMode: .list,
          navigationState: overallAppState.navigationState,
          listState: overallAppState.listState,
          archiveState: overallAppState.archiveState,
          overallAppState: overallAppState
        )
      case .downloaded:
        DownloadedListView(
          archiveState: overallAppState.archiveState,
          navigationState: overallAppState.navigationState,
          overallAppState: overallAppState
        )
      case .tags:
        List(overallAppState.tagState.tags, selection: $overallAppState.navigationState.selectedDetailDestination) { tag in
          NavigationLink(value: DetailNavigationDestination.tag(tag)) {
            TagView(
              tag: tag,
              isFavorite: overallAppState.tagState.isTagFavorite(tag: tag),
              favorite: {
                overallAppState.tagState.toggleFavorite(tag: tag)
              }
            )
          }
        }
      case .none:
        Text("Select")
      }
    } detail: {
      NavigationStack(path: $overallAppState.navigationState.detailNavigationStack) {
        detailView
          .navigationDestination(for: DetailNavigationDestination.self) { navigationLink in
            switch navigationLink {
            case .link(let link):
              ItemDetailView(
                link: link,
                overallAppState: overallAppState
              )
              #if os(macOS)
              .inspector(isPresented: $overallAppState.navigationState.showLinkEditorSidebar) {
                LinkEditView(
                  editState: overallAppState.editState,
                  showCancelButton: false
                )
                .onAppear { overallAppState.editState.load(link: link) }
              }
              #endif
            case .archiveLink(let archiveLink):
              DataWebView(archiveLink: archiveLink)
                .toolbar {
                  #if os(iOS)
                  ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                      overallAppState.navigationState.presentedEditArchiveLink = archiveLink
                    }
                  }
                  #else
                  ToolbarItem {
                    Button("Edit") {
                      overallAppState.navigationState.presentedEditArchiveLink = archiveLink
                    }
                  }
                  #endif
                }
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .navigationTitle(archiveLink.title ?? "")
            default:
              Text("Empty")
            }
          }
      }
      .sheet(item: $overallAppState.navigationState.presentedEditArchiveLink) { archiveLink in
        NavigationView {
          LinkEditView(
            editState: overallAppState.editState,
            showCancelButton: true
          )
          .onAppear {
            overallAppState.editState.load(archiveLink: archiveLink)
          }
          .onDisappear {
            overallAppState.editState.reset()
          }
          .navigationTitle("Edit Archive")
        }
      }
    }
    .alert(item: $overallAppState.archiveState.presentedError) { error in
      Alert(
        title: Text(error.title),
        message: Text(error.message),
        dismissButton: .default(Text("OK"))
      )
    }
  }

  @ViewBuilder
  private var detailView: some View {
    @Bindable var overallAppState = overallAppState
    switch overallAppState.navigationState.selectedDetailDestination {
    case .link(let link):
      ItemDetailView(
        link: link,
        overallAppState: overallAppState
      )
      #if os(macOS)
      // TODO: Add inspector for iOS
      .inspector(isPresented: $overallAppState.navigationState.showLinkEditorSidebar) {
        LinkEditView(
          editState: overallAppState.editState,
          showCancelButton: false
        )
        .onAppear { overallAppState.editState.load(link: link) }
      }
      .onChange(of: overallAppState.navigationState.selectedDetailDestination) { _, newValue in
        switch newValue {
        case .link(let newLink):
          overallAppState.editState.load(link: newLink)
        default:
          overallAppState.editState.reset()
        }
      }
      #endif
    case .archiveLink(let archiveLink):
      DataWebView(archiveLink: archiveLink)
      #if os(macOS)
      .inspector(isPresented: $overallAppState.navigationState.showLinkEditorSidebar) {
        LinkEditView(
          editState: overallAppState.editState,
          showCancelButton: false
        )
        .onAppear { overallAppState.editState.load(archiveLink: archiveLink) }
      }
      .onChange(of: overallAppState.navigationState.selectedDetailDestination) { _, newValue in
        switch newValue {
        case .archiveLink(let newArchiveLink):
          overallAppState.editState.load(archiveLink: newArchiveLink)
        default:
          overallAppState.editState.reset()
        }
      }
      .toolbar {
        ToolbarItem {
          Button {
            overallAppState.navigationState.showLinkEditorSidebar.toggle()
          } label: {
            Label("Show Edit Link", systemImage: "sidebar.right")
          }
        }
      }
      #endif
        .toolbar {
          ToolbarItem {
            ShareLink(item: archiveLink.url) {
              Label("Share", systemImage: "square.and.arrow.up")
            }
          }
        }
    case .tag(let tag):
      tagListContentView(selectedTag: tag)
    case .empty, .none:
      EmptyDetailView()
    }
  }

  @ViewBuilder
  private func tagListContentView(selectedTag: Tag) -> some View {
    ContentView(
      title: selectedTag.name,
      listType: .tagScoped(selectedTag),
      presentationMode: .detail,
      navigationState: overallAppState.navigationState,
      listState: overallAppState.listState,
      archiveState: overallAppState.archiveState,
      overallAppState: overallAppState
    )
  }

  private var networkingAlert: Alert {
    Alert(
      title: Text("Networking Error"),
      message: Text("Please try again.")
    )
  }
}
