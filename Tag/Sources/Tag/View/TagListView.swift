import SwiftUI
import Types

public struct TagListView: View {
    var tagState: TagState

    public init(
        tagState: TagState
    ) {
        self.tagState = tagState
    }

    public var body: some View {
        List(tagState.tags) { tag in
            NavigationLink(value: ListType.tags(selectedTag: tag)) {
                TagView(
                    tag: tag,
                    isFavorite: tagState.isTagFavorite(tag: tag),
                    favorite: {
                        tagState.toggleFavorite(tag: tag)
                    }
                )
            }
        }
    }
}
