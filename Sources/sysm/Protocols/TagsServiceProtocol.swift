import Foundation

/// Protocol for Finder tags service operations
protocol TagsServiceProtocol {
    func getTags(path: String) throws -> [TagsService.FinderTag]
    func setTags(path: String, tags: [TagsService.FinderTag]) throws
    func addTag(path: String, name: String, color: Int) throws
    func removeTag(path: String, name: String) throws
    func findByTag(name: String, scope: String?) throws -> [String]
}
