//
//  LinkAddView.swift
//  Aarlo
//
//  Created by martinhartl on 06.01.22.
//

import SwiftUI
import SwiftUIX
import Types
import LinkPresentation

struct LinkAddView: View {
  @Environment(\.presentationMode) var presentationMode

  var overallAppState: OverallAppState

  private var localAddLink: PostLink?
  @FocusState private var isEditingURL: Bool

  init(
    overallAppState: OverallAppState,
    urlString: String = "",
    title: String = "",
    description: String = ""
  ) {
    self.overallAppState = overallAppState
  }

  var body: some View {
    #if os(macOS)
      form
        .padding()
    #else
      NavigationView {
        form
          .navigationTitle("Add Link")
      }
    #endif
  }

  var form: some View {
    @Bindable var overallAppState = overallAppState
    return Form {
      Section(header: "Main Information") {
        TextField("URL", text: $overallAppState.addState.urlString)
          .disableAutocorrection(true)
          .disabled(overallAppState.addState.isLoadingMetadata)
          .focused($isEditingURL)
          .onSubmit {
            handleURLChange(overallAppState.addState.urlString)
          }
        TextField("Title", text: $overallAppState.addState.title)
          .disabled(overallAppState.addState.isLoadingMetadata)
      }
      Section(header: "Description") {
        TextEditor(text: $overallAppState.addState.description)
          .disabled(overallAppState.addState.isLoadingMetadata)
          .overlay(alignment: .topLeading) {
            if overallAppState.addState.isLoadingMetadata {
              ProgressView().padding(.top, 4)
            }
          }
      }
      Section(header: "Favorites") {
        ForEach(overallAppState.tagState.favoriteTags) { tag in
          Toggle(
            tag.name,
            isOn: Binding(
              get: {
                overallAppState.tagState.tagsString(
                  overallAppState.addState.tagsString, contains: tag)
              },
              set: { newValue in
                if newValue {
                  overallAppState.addState.tagsString = overallAppState.tagState.addingTag(
                    tag, toTagsString: overallAppState.addState.tagsString)
                } else {
                  overallAppState.addState.tagsString = overallAppState.tagState.removingTag(
                    tag, fromTagsString: overallAppState.addState.tagsString)
                }
              }
            )
          )
        }
      }
      TextField("Tags", text: $overallAppState.addState.tagsString)
        .disableAutocorrection(true)
      Button("Add") {
        save()
      }.disabled(saveButtonDisabled || overallAppState.addState.isLoadingMetadata)
    }
    .onChange(of: isEditingURL) { isEditing in
      if isEditing == false {
        handleURLChange(overallAppState.addState.urlString)
      }
    }
  }

  private var saveButtonDisabled: Bool {
    guard !overallAppState.addState.urlString.isEmpty,
      URL(string: overallAppState.addState.urlString) != nil
    else {
      return true
    }

    let detector = try! NSDataDetector(
      types: NSTextCheckingResult.CheckingType.link.rawValue)
    let matches = detector.matches(
      in: overallAppState.addState.urlString, options: [],
      range: NSRange(location: 0, length: overallAppState.addState.urlString.utf16.count))

    return matches.count == 0
  }

  private func save() {
    guard let url = URL(string: overallAppState.addState.urlString) else {
      return
    }

    let tags = overallAppState.addState.tagsString.components(separatedBy: " ")
    let newLink = PostLink(
      url: url,
      title: overallAppState.addState.title,
      description: overallAppState.addState.description,
      tags: tags,
      private: false,
      created: Date().addingTimeInterval(-10.0)
    )

    Task {
      await overallAppState.listState.add(link: newLink)
      presentationMode.dismiss()
    }
  }

  private func handleURLChange(_ newValue: String) {
    guard let url = URL(string: newValue), !newValue.isEmpty else { return }
    // Trigger only when user pastes or finishes typing a plausible URL
    let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
    let range = NSRange(location: 0, length: newValue.utf16.count)
    guard detector.firstMatch(in: newValue, options: [], range: range) != nil else { return }

    // Avoid refetching if same URL
    if overallAppState.addState.title.isEmpty == false || overallAppState.addState.description.isEmpty == false {
      return
    }

    overallAppState.addState.isLoadingMetadata = true
    let provider = LPMetadataProvider()
    provider.startFetchingMetadata(for: url) { metadata, error in
      DispatchQueue.main.async {
        overallAppState.addState.isLoadingMetadata = false
        guard error == nil, let metadata else { return }
        if overallAppState.addState.title.isEmpty, let title = metadata.title {
          overallAppState.addState.title = title
        }
      }
    }
  }
}
