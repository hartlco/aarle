import Foundation

public protocol BookmarkClient {
    var pageSize: Int { get }

    func load(filteredByTags tags: [String], searchTerm: String?) async throws -> [Link]
    func loadMore(offset: Int, filteredByTags tags: [String], searchTerm: String?) async throws -> [Link]
    func createLink(link: PostLink) async throws
    func updateLink(link: Link) async throws
    func deleteLink(link: Link) async throws
    func loadTags() async throws -> [Tag]
}
