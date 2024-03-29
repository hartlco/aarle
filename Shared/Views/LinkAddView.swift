//
//  LinkAddView.swift
//  Aarlo
//
//  Created by martinhartl on 06.01.22.
//

import SwiftUI
import SwiftUIX
import Types

struct LinkAddView: View {
    @Environment(\.presentationMode) var presentationMode

    var overallAppState: OverallAppState

    @State var urlString: String
    @State var title: String
    @State var description: String
    @State var tagsString: String

    private var localAddLink: PostLink?

    init(
        overallAppState: OverallAppState,
        urlString: String = "",
        title: String = "",
        description: String = ""
    ) {
        self.overallAppState = overallAppState
        _urlString = State<String>(initialValue: urlString)
        _title = State(initialValue: title)
        _description = State(initialValue: description)
        _tagsString = State(initialValue: "")
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
        Form {
            Section(header: "Main Information") {
                TextField("URL", text: $urlString)
                    .disableAutocorrection(true)
                TextField("Title", text: $title)
            }
            Section(header: "Description") {
                TextEditor(text: $description)
            }
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
            TextField("Tags", text: $tagsString)
                .disableAutocorrection(true)
            Button("Add") {
                save()
            }.disabled(saveButtonDisabled)
        }
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
            await overallAppState.listState.add(link: newLink)
            presentationMode.dismiss()
        }
    }
}
