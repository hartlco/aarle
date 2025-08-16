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

    private var form: some View {
        @Bindable var editState = editState
        return VStack(alignment: .leading, spacing: 10) {
            Section(header: "Main Information") {
                TextField("Link", text: $editState.urlString)
                    .disableAutocorrection(true)
                TextField("Title", text: $editState.title)
            }
            Section(header: "Description") {
                TextEditor(text: $editState.description)
            }
            if !editState.favoriteTags.isEmpty {
                Section(header: "Favorites") {
                    ForEach(editState.favoriteTags) { tag in
                        Toggle(
                            tag.name,
                            isOn: Binding(
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
                            )
                        )
                    }
                }
            }
            TextField("Tags", text: $editState.tagsString)
                .disableAutocorrection(true)
        }
    }

    private var macOSForm: some View {
        @Bindable var editState = editState
        return HStack {
            VStack {
                Form {
                    TextField("Link:", text: $editState.urlString)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disableAutocorrection(true)
                    TextField("Title:", text: $editState.title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    TextEditor(text: $editState.description)
                        .formLabel(Text("Notes:"))
                        .frame(maxHeight: 400)
                    TextField("Tags:", text: $editState.tagsString)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disableAutocorrection(true)
                    if !editState.favoriteTags.isEmpty {
                        ForEach(editState.favoriteTags) { tag in
                            Toggle(
                                tag.name,
                                isOn: Binding(
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
                                )
                            )
                        }
                    }
                    Spacer()
                    HStack {
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
            }
            Spacer()
        }
        .padding()
    }
    
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
                TextField("Comma-separated tags", text: $editState.tagsString)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
        }
    }
}

/// https://gist.github.com/marcprux/afd2f80baa5b6d60865182a828e83586
/// Alignment guide for aligning a text field in a `Form`.
/// Thanks for Jim Dovey  https://developer.apple.com/forums/thread/126268
extension HorizontalAlignment {
    private enum ControlAlignment: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            return context[HorizontalAlignment.center]
        }
    }

    static let controlAlignment = HorizontalAlignment(ControlAlignment.self)
}

public extension View {
    /// Attaches a label to this view for laying out in a `Form`
    /// - Parameter view: the label view to use
    /// - Returns: an `HStack` with an alignment guide for placing in a form
    func formLabel<V: View>(_ view: V) -> some View {
        HStack {
            view
            self
                .alignmentGuide(.controlAlignment) { $0[.leading] }
        }
        .alignmentGuide(.leading) { $0[.controlAlignment] }
    }
}
