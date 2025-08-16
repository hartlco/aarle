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
  var onCancel: (() -> Void)?

  private var localAddLink: PostLink?
  @FocusState private var isEditingURL: Bool

  init(
    overallAppState: OverallAppState,
    urlString: String = "",
    title: String = "",
    description: String = "",
    onCancel: (() -> Void)? = nil
  ) {
    self.overallAppState = overallAppState
    self.onCancel = onCancel
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
      
      Section(header: "Options") {
        Toggle("Download for offline reading", isOn: $overallAppState.addState.shouldArchive)
      }
      
      HStack {
        if onCancel != nil {
          Button("Cancel") {
            onCancel?()
          }
          .buttonStyle(.bordered)
        }
        
        Spacer()
        
        Button(action: {
          save()
        }) {
          HStack {
            if overallAppState.addState.isSaving {
              ProgressView()
                .scaleEffect(0.8)
            }
            Text("Add")
          }
        }
        .buttonStyle(.borderedProminent)
        .disabled(saveButtonDisabled || overallAppState.addState.isLoadingMetadata || overallAppState.addState.isSaving)
      }
    }
    .onChange(of: isEditingURL) { _, isEditing in
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

    let tagString = overallAppState.addState.tagsString
    let tags = tagString.components(separatedBy: " ")

    // TODO: Adding tags while adding links doesnt work at all
    let newLink = PostLink(
      url: url,
      title: overallAppState.addState.title,
      description: overallAppState.addState.description,
      tags: tags,
      private: false,
      created: Date().addingTimeInterval(-10.0)
    )

    overallAppState.addState.isSaving = true

    Task {
      let createdLink = await overallAppState.listState.add(link: newLink)
      
      // Archive the link if the option is selected and link was created successfully
      if overallAppState.addState.shouldArchive, let createdLink = createdLink {
        await overallAppState.archiveState.archiveLink(link: createdLink)
      }
      
      await MainActor.run {
        overallAppState.addState.isSaving = false
        overallAppState.addState.onSaveComplete?()
        presentationMode.dismiss()
      }
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
    
    let metadataService = MetadataService(customEndpoint: overallAppState.settingsState.metadataEndpoint)
    
    Task {
      do {
        let metadata = try await metadataService.fetchMetadata(for: url)
        await MainActor.run {
          overallAppState.addState.isLoadingMetadata = false
          if overallAppState.addState.title.isEmpty, let title = metadata.title {
            overallAppState.addState.title = title
          }
          if overallAppState.addState.description.isEmpty, let description = metadata.description {
            overallAppState.addState.description = description
          }
        }
      } catch {
        await MainActor.run {
          overallAppState.addState.isLoadingMetadata = false
        }
      }
    }
  }
}
