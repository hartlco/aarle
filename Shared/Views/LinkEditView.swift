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

    @EnvironmentObject var linkStore: LinkViewStore
    @EnvironmentObject var tagViewStore: TagViewStore
    @EnvironmentObject var appViewStore: AppViewStore

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
        self._urlString = State<String>(initialValue: link.url.absoluteString)
        self._title = State(initialValue: link.title ?? "")
        self._description = State(initialValue: link.description ?? "")
        self._tagsString = State(initialValue: link.tags.joined(separator: " "))
    }

    var body: some View {
#if os(macOS)
        macOSForm
#elseif os(iOS)
        form.toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel", role: .cancel) {
                    dismiss()
                }.hidden(!showCancelButton)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    save()
                    if showCancelButton {
                        dismiss()
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
            if !tagViewStore.favoriteTags.isEmpty {
                Section(header: "Favorites") {
                    ForEach(tagViewStore.favoriteTags) { tag in
                        Toggle(
                            tag.name,
                            isOn: Binding(
                                get: {
                                    return tagViewStore.tagsString(tagsString, contains: tag)
                                },
                                set: { newValue in
                                    if newValue {
                                        tagsString = tagViewStore.addingTag(tag, toTagsString: tagsString)
                                    } else {
                                        tagsString = tagViewStore.removingTag(tag, fromTagsString: tagsString)
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
        HStack{
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
                    if !tagViewStore.favoriteTags.isEmpty {
                        ForEach(tagViewStore.favoriteTags) { tag in
                            Toggle(
                                tag.name,
                                isOn: Binding(
                                    get: {
                                        return tagViewStore.tagsString(tagsString, contains: tag)
                                    },
                                    set: { newValue in
                                        if newValue {
                                            tagsString = tagViewStore.addingTag(tag, toTagsString: tagsString)
                                        } else {
                                            tagsString = tagViewStore.removingTag(tag, fromTagsString: tagsString)
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
                                appViewStore.send(.hideEditLink)
                            }
                            .keyboardShortcut(.cancelAction)
                        }
                        Button("Save") {
                            save()
                            if showCancelButton {
                                appViewStore.send(.hideEditLink)
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

        linkStore.send(.update(newLink))
    }
}

#if DEBUG
struct LinkEditView_Previews: PreviewProvider {
    static var previews: some View {
        let link = Link.mock
        LinkEditView(
            link: link,
            showCancelButton: true
        )
            .environmentObject(TagViewStore.mock)
            .environmentObject(LinkViewStore.mock)
    }
}
#endif

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
