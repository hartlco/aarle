import SwiftUI
import Types

public struct TagListView: View {
    @ObservedObject var tagState: TagState
    @Binding var selectionState: ListType?

    public init(
        tagState: TagState,
        selectionState: Binding<ListType?>
    ) {
        self.tagState = tagState
        self._selectionState = selectionState
    }

    public var body: some View {
        List(tagState.tags, selection: $selectionState) { tag in
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
