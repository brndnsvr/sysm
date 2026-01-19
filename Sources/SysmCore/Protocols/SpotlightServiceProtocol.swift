import Foundation

/// Protocol defining Spotlight search service operations using mdfind and mdls.
///
/// Implementations provide file search capabilities using macOS Spotlight index,
/// supporting query search, file type filtering, modification date queries, and metadata retrieval.
public protocol SpotlightServiceProtocol: Sendable {
    /// Searches files using Spotlight query syntax.
    /// - Parameters:
    ///   - query: Spotlight query string.
    ///   - scope: Optional directory to limit search scope.
    ///   - limit: Optional maximum number of results.
    /// - Returns: Array of search results.
    func search(query: String, scope: String?, limit: Int?) throws -> [SpotlightService.SearchResult]

    /// Searches files by content type.
    /// - Parameters:
    ///   - kind: File kind (e.g., "pdf", "image", "document").
    ///   - scope: Optional directory to limit search scope.
    ///   - limit: Optional maximum number of results.
    /// - Returns: Array of search results.
    func searchByKind(kind: String, scope: String?, limit: Int?) throws -> [SpotlightService.SearchResult]

    /// Searches for files modified within a time range.
    /// - Parameters:
    ///   - days: Number of days back to search.
    ///   - scope: Optional directory to limit search scope.
    ///   - limit: Optional maximum number of results.
    /// - Returns: Array of search results.
    func searchModified(days: Int, scope: String?, limit: Int?) throws -> [SpotlightService.SearchResult]

    /// Retrieves Spotlight metadata for a file.
    /// - Parameter path: Path to the file.
    /// - Returns: File metadata attributes.
    func getMetadata(path: String) throws -> SpotlightService.FileMetadata
}
