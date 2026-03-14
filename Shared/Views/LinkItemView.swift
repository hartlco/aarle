import SwiftUI
import Types

protocol LinkItemViewRepresentation {
    var title: String? { get }
    var url: URL { get }
    var description: String? { get }
    var tags: [String] { get }
    var previewImageUrl: URL? { get }
}

extension Types.Link: LinkItemViewRepresentation {}
extension ArchiveLink: LinkItemViewRepresentation {
    var previewImageUrl: URL? { nil }
}

struct LinkItemView: View {
    let link: LinkItemViewRepresentation

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                if let title = link.title {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                }
                Text(link.url.host ?? link.url.absoluteString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let description = link.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                if !link.tags.isEmpty {
                    Text(link.tags.joined(separator: " · "))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
            if let previewImageUrl = link.previewImageUrl {
                AsyncImage(url: previewImageUrl) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.15))
                }
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.vertical, 4)
    }
}
