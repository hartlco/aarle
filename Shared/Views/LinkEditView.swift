//
//  LinkEditView.swift
//  Aarlo
//
//  Created by martinhartl on 06.01.22.
//

import SwiftUI
import SwiftUIX

struct LinkEditView: View {
    let link: Link

    @EnvironmentObject var overallAppState: OverallAppState

    // TODO: Move into EditStore
    @State var urlString: String
    @State var title: String
    @State var description: String
    @State var tagsString: String

    private let showCancelButton: Bool

    init(
        link: Link,
        showCancelButton: Bool
    ) {
        self.link = link
        self.showCancelButton = showCancelButton
        _urlString = State<String>(initialValue: link.url.absoluteString)
        _title = State(initialValue: link.title ?? "")
        _description = State(initialValue: link.description ?? "")
        _tagsString = State(initialValue: link.tags.joined(separator: " "))
    }

    var body: some View {
        #if os(macOS)
            macOSForm
        #elseif os(iOS)
            form.toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", role: .cancel) {
                        overallAppState.presentedEditLink = nil
                    }.hidden(!showCancelButton)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        save()
                        if showCancelButton {
                            overallAppState.presentedEditLink = nil
                        }
                    }
                }
            }.navigationTitle("Edit link")
        #endif
    }

    private var form: some View {
        Form {
            Section(header: "Main Information") {
                TextField("Link", text: $urlString)
                    .disableAutocorrection(true)
                TextField("Title", text: $title)
            }
            Section(header: "Description") {
                TextEditor(text: $description)
            }
            if !overallAppState.tagState.favoriteTags.isEmpty {
                Section(header: "Favorites") {
                    ForEach(overallAppState.tagState.favoriteTags) { tag in
                        Toggle(
                            tag.name,
                            isOn: Binding(
                                get: {
                                    overallAppState.tagState.tagsString(tagsString, contains: tag)
                                },
                                set: { newValue in
                                    if newValue {
                                        tagsString = overallAppState.tagState.addingTag(tag, toTagsString: tagsString)
                                    } else {
                                        tagsString = overallAppState.tagState.removingTag(tag, fromTagsString: tagsString)
                                    }
                                }
                            )
                        )
                    }
                }
            }
            TextField("Tags", text: $tagsString)
                .disableAutocorrection(true)
        }
    }

    private var macOSForm: some View {
        HStack {
            Spacer()
            VStack {
                Spacer()
                Form {
                    TextField("Link:", text: $urlString)
                        .disableAutocorrection(true)
                    TextField("Title:", text: $title)
                    TextEditor(text: $description)
                        .formLabel(Text("Notes:"))
                        .frame(maxHeight: 400)
                    TextField("Tags:", text: $tagsString)
                        .disableAutocorrection(true)
                    if !overallAppState.tagState.favoriteTags.isEmpty {
                        ForEach(overallAppState.tagState.favoriteTags) { tag in
                            Toggle(
                                tag.name,
                                isOn: Binding(
                                    get: {
                                        overallAppState.tagState.tagsString(tagsString, contains: tag)
                                    },
                                    set: { newValue in
                                        if newValue {
                                            tagsString = overallAppState.tagState.addingTag(tag, toTagsString: tagsString)
                                        } else {
                                            tagsString = overallAppState.tagState.removingTag(tag, fromTagsString: tagsString)
                                        }
                                    }
                                )
                            )
                        }
                    }
                    HStack {
                        Spacer()
                        if showCancelButton {
                            Button("Cancel", role: .cancel) {
                                overallAppState.presentedEditLink = nil
                            }
                            .keyboardShortcut(.cancelAction)
                        }
                        Button("Save") {
                            save()
                            if showCancelButton {
                                overallAppState.presentedEditLink = nil
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut("s", modifiers: [.command])
                    }
                }
                Spacer()
            }
            Spacer()
        }
    }

    private func save() {
        let url = URL(string: urlString) ?? link.url
        let tags = tagsString.components(separatedBy: " ")
        let newLink = Link(
            id: link.id,
            url: url,
            title: title,
            description: description,
            tags: tags,
            private: false,
            created: link.created
        )

        Task {
            await overallAppState.update(link: newLink)
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
