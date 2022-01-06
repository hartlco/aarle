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
            Text("Edit Link")
                .font(.title)
            TextField("URL:", text: $urlString)
            TextField("Title:", text: $title)
            VStack {
                Text("Description")
                TextEditor(text: $description)
            }
            TextField("Tags:", text: $tagsString)
            Button("Save") {
                save()
            }
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
        LinkEditView(link: link, linkStore: LinkStore.mock)
    }
}
#endif
