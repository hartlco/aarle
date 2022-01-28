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

    @ObservedObject private var linkStore: LinkStore
    @EnvironmentObject var tagStore: TagStore

    @State var urlString: String
    @State var title: String
    @State var description: String
    @State var tagsString: String

    init(
        link: Link,
        linkStore: LinkStore
    ) {
        self.link = link
        self.linkStore = linkStore
        self._urlString = State<String>(initialValue: link.url.absoluteString)
        self._title = State(initialValue: link.title ?? "")
        self._description = State(initialValue: link.description ?? "")
        self._tagsString = State(initialValue: link.tags.joined(separator: " "))
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
            Button("Save") {
                save()
            }
        }
        .padding()
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
        LinkEditView(link: link,
                     linkStore: .mock).environmentObject(TagStore.mock)
    }
}
#endif
