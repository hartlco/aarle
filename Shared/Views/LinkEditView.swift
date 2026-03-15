//
//  LinkEditView.swift
//  Aarlo
//
//  Created by martinhartl on 06.01.22.
//

import SwiftUI
import SwiftUIX
import Types

struct LinkEditView: View {
    var editState: EditState
    private let showCancelButton: Bool

    init(
        editState: EditState,
        showCancelButton: Bool
    ) {
        self.editState = editState
        self.showCancelButton = showCancelButton
    }

    var body: some View {
        @Bindable var editState = editState
        #if os(macOS)
            macOSForm
        #elseif os(iOS)
            iOSForm.toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", role: .cancel) {
                        editState.closeEditUI()
                    }.hidden(!showCancelButton)
                }
                if editState.isEditingArchiveLink {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            Task { await editState.markCurrentAsRead() }
                        } label: {
                            Label("Mark as Read", systemImage: "checkmark.circle")
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task { await editState.save() }
                        if showCancelButton {
                            editState.closeEditUI()
                        }
                    }
                    .fontWeight(.semibold)
                }
            }.navigationTitle("Edit Link")
        #endif
    }

    private var macOSForm: some View {
        @Bindable var editState = editState
        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                BookmarkFormFields(
                    urlString: $editState.urlString,
                    title: $editState.title,
                    description: $editState.description,
                    tagsString: $editState.tagsString,
                    allTags: editState.allTags,
                    favoriteTags: editState.favoriteTags,
                    isDisabled: false,
                    onToggleFavorite: { tag, isOn in
                        if isOn {
                            editState.appendTag(tag)
                        } else {
                            editState.removeTag(tag)
                        }
                    }
                )

                if !editState.isEditingArchiveLink {
                    Toggle("Unread", isOn: $editState.unread)
                }

                HStack {
                    if editState.isEditingArchiveLink {
                        Button {
                            Task { await editState.markCurrentAsRead() }
                        } label: {
                            Label("Mark as Read", systemImage: "checkmark.circle")
                        }
                    }
                    Spacer()
                    if showCancelButton {
                        Button("Cancel", role: .cancel) {
                            editState.closeEditUI()
                        }
                        .keyboardShortcut(.cancelAction)
                    }
                    Button("Save") {
                        Task { await editState.save() }
                        if showCancelButton {
                            editState.closeEditUI()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut("s", modifiers: [.command])
                }
            }
            .padding()
        }
    }
#if os(iOS)
    private var iOSForm: some View {
        @Bindable var editState = editState
        return Form {
            Section("Link Information") {
                TextField("URL", text: $editState.urlString)
                    .keyboardType(.URL)
                    .textContentType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                
                TextField("Title", text: $editState.title)
                    .textContentType(.name)
            }
            
            Section("Description") {
                TextField("Add notes about this link...", text: $editState.description, axis: .vertical)
                    .lineLimit(3...8)
            }
            
            if !editState.favoriteTags.isEmpty {
                Section("Favorite Tags") {
                    ForEach(editState.favoriteTags) { tag in
                        Toggle(tag.name, isOn: Binding(
                            get: {
                                editState.tagsStringContains(tag)
                            },
                            set: { newValue in
                                if newValue {
                                    editState.appendTag(tag)
                                } else {
                                    editState.removeTag(tag)
                                }
                            }
                        ))
                    }
                }
            }
            
            Section("Tags") {
                TagTextField(
                    tagsString: $editState.tagsString,
                    allTags: editState.allTags,
                    placeholder: "Space-separated tags"
                )
            }

            if !editState.isEditingArchiveLink {
                Section("Status") {
                    Toggle("Unread", isOn: $editState.unread)
                }
            }
        }
    }
#endif
}

