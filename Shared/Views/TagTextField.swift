import SwiftUI
import Types

struct TagTextField: View {
    @Binding var tagsString: String
    let allTags: [Types.Tag]
    let placeholder: String

    @State private var showSuggestions = false
    @FocusState private var isFocused: Bool

    init(
        tagsString: Binding<String>,
        allTags: [Types.Tag],
        placeholder: String = "Tags"
    ) {
        self._tagsString = tagsString
        self.allTags = allTags
        self.placeholder = placeholder
    }

    private var currentWord: String {
        let components = tagsString.components(separatedBy: " ")
        return components.last ?? ""
    }

    private var existingTags: Set<String> {
        Set(
            tagsString.components(separatedBy: " ")
                .filter { !$0.isEmpty }
        )
    }

    private var suggestions: [Types.Tag] {
        let word = currentWord.lowercased()
        guard !word.isEmpty else { return [] }

        return allTags.filter { tag in
            let name = tag.name.lowercased()
            return name.contains(word)
                && name != word
                && !existingTags.contains(tag.name)
        }
        .prefix(6)
        .map { $0 }
    }

    var body: some View {
        TextField(placeholder, text: $tagsString)
            .autocorrectionDisabled()
            #if os(iOS)
            .textInputAutocapitalization(.never)
            #endif
            .focused($isFocused)
            .onChange(of: tagsString) {
                showSuggestions = !currentWord.isEmpty && !suggestions.isEmpty
            }
            .onChange(of: isFocused) {
                if !isFocused {
                    // Delay hide so tap on suggestion registers
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        showSuggestions = false
                    }
                }
            }
            .overlay(alignment: .topLeading) {
                if showSuggestions && !suggestions.isEmpty {
                    suggestionList
                        .offset(y: 36)
                }
            }
            .zIndex(1)
    }

    private var suggestionList: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(suggestions) { tag in
                Button {
                    selectTag(tag)
                } label: {
                    HStack {
                        Text(tag.name)
                            .font(.subheadline)
                        if let count = tag.occurrences {
                            Spacer()
                            Text("\(count)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if tag.id != suggestions.last?.id {
                    Divider()
                }
            }
        }
        #if os(iOS)
        .background(Color(.secondarySystemBackground))
        #else
        .background(Color(.controlBackgroundColor))
        #endif
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
    }

    private func selectTag(_ tag: Types.Tag) {
        var components = tagsString.components(separatedBy: " ")
        // Replace the last (partial) word with the selected tag
        if !components.isEmpty {
            components[components.count - 1] = tag.name
        } else {
            components.append(tag.name)
        }
        // Add trailing space so user can continue typing
        tagsString = components.joined(separator: " ") + " "
        showSuggestions = false
    }
}
