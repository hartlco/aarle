//
//  BookmarkFormFields.swift
//  Aarle
//
//  Shared macOS form fields for Add and Edit bookmark views.
//

import SwiftUI
import Types

struct BookmarkFormFields: View {
    @Binding var urlString: String
    @Binding var title: String
    @Binding var description: String
    @Binding var tagsString: String
    var allTags: [Tag]
    var favoriteTags: [Tag]
    var isDisabled: Bool
    var onToggleFavorite: (Tag, Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            fieldSection("URL") {
                TextField("URL", text: $urlString)
                    .disableAutocorrection(true)
                    .disabled(isDisabled)
            }

            fieldSection("Title") {
                TextField("Title", text: $title)
                    .disabled(isDisabled)
            }

            fieldSection("Description") {
                TextEditor(text: $description)
                    .frame(minHeight: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
                    .disabled(isDisabled)
            }

            if !favoriteTags.isEmpty {
                fieldSection("Favorites") {
                    FlowLayout(spacing: 8) {
                        ForEach(favoriteTags) { tag in
                            Toggle(
                                tag.name,
                                isOn: Binding(
                                    get: { isTagActive(tag) },
                                    set: { onToggleFavorite(tag, $0) }
                                )
                            )
                            .toggleStyle(.button)
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }

            fieldSection("Tags") {
                TagTextField(
                    tagsString: $tagsString,
                    allTags: allTags,
                    placeholder: "Space-separated tags"
                )
            }
        }
        .textFieldStyle(.roundedBorder)
    }

    private func isTagActive(_ tag: Tag) -> Bool {
        let tags = tagsString.components(separatedBy: " ").filter { !$0.isEmpty }
        return tags.contains(tag.name)
    }

    @ViewBuilder
    private func fieldSection<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.headline)
                .foregroundStyle(.secondary)
            content()
        }
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var height: CGFloat = 0
        for (index, row) in rows.enumerated() {
            let rowHeight = row.map { subviews[$0].sizeThatFits(.unspecified).height }.max() ?? 0
            height += rowHeight
            if index < rows.count - 1 { height += spacing }
        }
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            let rowHeight = row.map { subviews[$0].sizeThatFits(.unspecified).height }.max() ?? 0
            var x = bounds.minX
            for index in row {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += rowHeight + spacing
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[Int]] {
        let maxWidth = proposal.width ?? .infinity
        var rows: [[Int]] = [[]]
        var currentWidth: CGFloat = 0
        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            if currentWidth + size.width > maxWidth && !rows[rows.count - 1].isEmpty {
                rows.append([])
                currentWidth = 0
            }
            rows[rows.count - 1].append(index)
            currentWidth += size.width + spacing
        }
        return rows
    }
}
