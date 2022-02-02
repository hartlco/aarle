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

    @Environment(\.dismiss) var dismiss

    @EnvironmentObject var linkStore: LinkStore
    @EnvironmentObject var tagStore: TagStore

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
        form
        .padding()
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
                TextField("URL", text: $urlString)
                TextField("Title", text: $title)
            }
            Section(header: "Description") {
                TextEditor(text: $description)
            }
            if !tagStore.favoriteTags.isEmpty {
                Section(header: "Favorites") {
                    ForEach(tagStore.favoriteTags) { tag in
                        Toggle(
                            tag.name,
                            isOn: Binding(
                                get: {
                                    return tagStore.tagsString(tagsString, contains: tag)
                                },
                                set: { newValue in
                                    if newValue {
                                        tagsString = tagStore.addingTag(tag, toTagsString: tagsString)
                                    } else {
                                        tagsString = tagStore.removingTag(tag, fromTagsString: tagsString)
                                    }
                                }
                            )
                        )
                    }
                }
            }
            TextField("Tags:", text: $tagsString)
#if os(macOS)
            HStack {
                Spacer()
                if showCancelButton {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                }
                Button("Save") {
                    save()
                    if showCancelButton {
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut("s", modifiers: [.command])
            }
#endif
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
            try await linkStore.update(link: newLink)
        }
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
            .environmentObject(TagStore.mock)
            .environmentObject(LinkStore.mock)
    }
}
#endif
