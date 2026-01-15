import Foundation

/// Protocol for Spotlight search service operations
protocol SpotlightServiceProtocol {
    func search(query: String, scope: String?, limit: Int?) throws -> [SpotlightService.SearchResult]
    func searchByKind(kind: String, scope: String?, limit: Int?) throws -> [SpotlightService.SearchResult]
    func searchModified(days: Int, scope: String?, limit: Int?) throws -> [SpotlightService.SearchResult]
    func getMetadata(path: String) throws -> SpotlightService.FileMetadata
}
