//
//  LinkAddView.swift
//  Aarlo
//
//  Created by martinhartl on 06.01.22.
//

import SwiftUI
import SwiftUIX

struct LinkAddView: View {
    @ObservedObject private var linkStore: LinkStore
    @ObservedObject private var tagStore: TagStore

    @Environment(\.presentationMode) var presentationMode

    @State var urlString: String
    @State var title: String
    @State var description: String
    @State var tagsString: String

    init(
        linkStore: LinkStore,
        tagStore: TagStore,
        urlString: String = ""
    ) {
        self.linkStore = linkStore
        self.tagStore = tagStore
        self._urlString = State<String>(initialValue: urlString)
        self._title = State(initialValue: "")
        self._description = State(initialValue: "")
        self._tagsString = State(initialValue: "")
    }

    var body: some View {
        Form {
            Section(header: "Main Information") {
                TextField("URL:", text: $urlString)
                TextField("Title:", text: $title)
            }
            Section(header: "Description") {
                TextEditor(text: $description)
            }
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
            TextField("Tags:", text: $tagsString)
            Button("Add") {
                save()
            }.disabled(saveButtonDisabled)
        }
        .padding()
    }

    private var saveButtonDisabled: Bool {
        guard !urlString.isEmpty,
              URL(string: urlString) != nil
        else {
            return true
        }

        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector.matches(in: urlString, options: [], range: NSRange(location: 0, length: urlString.utf16.count))

        return matches.count == 0
    }

    private func save() {
        guard let url = URL(string: urlString) else {
            return
        }

        let tags = tagsString.components(separatedBy: " ")
        let newLink = PostLink(
            url: url,
            title: title,
            description: description,
            tags: tags,
            private: false,
            created: Date().addingTimeInterval(-10.0)
        )

        Task {
            try await linkStore.add(link: newLink)
            presentationMode.dismiss()
        }
    }
}

#if DEBUG
struct LinkAddView_Previews: PreviewProvider {
    static var previews: some View {
        LinkAddView(linkStore: LinkStore.mock, tagStore: .mock)
    }
}
#endif
