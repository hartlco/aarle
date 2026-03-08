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
        HStack(alignment: .top, spacing: 8.0) {
            VStack(alignment: .leading, spacing: 2.0) {
                if let title = link.title {
                    Text(title)
                        .font(.title3)
                        .bold()
                }
                Text(link.url.host ?? link.url.absoluteString)
                    .foregroundColor(.accentColor)
                if let description = link.description, !description.isEmpty {
                    Text(description)
                        .lineLimit(0 ... 5)
                        .font(.body)
                }
                if !tagsString.isEmpty {
                    Text(tagsString)
                        .font(.footnote)
                        .foregroundColor(.secondaryLabel)
                        .padding(2.0)
                }
            }
            Spacer(minLength: 0)
            if let previewImageUrl = link.previewImageUrl {
                AsyncImage(url: previewImageUrl) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.clear
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(4.0)
    }

    private var tagsString: String {
        return link.tags.joined(separator: " • ")
    }
}
