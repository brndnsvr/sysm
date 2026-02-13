import Foundation

/// Protocol defining Spotlight search service operations using mdfind and mdls.
///
/// This protocol provides file search capabilities using the macOS Spotlight index through
/// the `mdfind` and `mdls` command-line tools. Supports query search, file type filtering,
/// modification date queries, and metadata retrieval.
///
/// ## Spotlight Query Syntax
///
/// Queries use Spotlight metadata attributes:
/// - `kMDItemDisplayName`: File name
/// - `kMDItemContentType`: File type (UTI)
/// - `kMDItemFSContentChangeDate`: Modification date
/// - And many more metadata attributes
///
/// ## Usage Example
///
/// ```swift
/// let service = SpotlightService()
///
/// // Search by query
/// let results = try service.search(
///     query: "kMDItemDisplayName == '*report*'",
///     scope: "~/Documents",
///     limit: 10
/// )
///
/// // Search by file kind
/// let pdfs = try service.searchByKind(
///     kind: "pdf",
///     scope: "~/Downloads",
///     limit: 20
/// )
///
/// // Find recently modified files
/// let recent = try service.searchModified(
///     days: 7,
///     scope: nil,  // All indexed locations
///     limit: 50
/// )
///
/// // Get file metadata
/// let metadata = try service.getMetadata(path: "/path/to/file.pdf")
/// print("Created: \(metadata.creationDate)")
/// ```
///
/// ## Thread Safety
///
/// Implementations are marked as `Sendable` and safe to use across actor boundaries.
/// Spotlight queries are synchronous and use the mdfind/mdls CLI tools.
///
/// ## Error Handling
///
/// Methods can throw ``SpotlightError`` variants:
/// - ``SpotlightError/invalidQuery(_:)`` - Malformed Spotlight query
/// - ``SpotlightError/fileNotFound(_:)`` - File doesn't exist for metadata query
/// - ``SpotlightError/searchFailed(_:)`` - mdfind execution failed
/// - ``SpotlightError/indexNotReady`` - Spotlight index not available
///
public protocol SpotlightServiceProtocol: Sendable {
    // MARK: - Search Operations

    /// Searches files using Spotlight query syntax.
    ///
    /// Executes a Spotlight metadata query to find matching files. Queries use Spotlight's
    /// rich metadata attribute syntax.
    ///
    /// - Parameters:
    ///   - query: Spotlight query string (e.g., `kMDItemDisplayName == '*project*'`).
    ///   - scope: Optional directory to limit search scope. If nil, searches all indexed locations.
    ///   - limit: Optional maximum number of results. If nil, returns all matches.
    /// - Returns: Array of ``SpotlightService/SearchResult`` objects.
    /// - Throws:
    ///   - ``SpotlightError/invalidQuery(_:)`` if query syntax is invalid.
    ///   - ``SpotlightError/searchFailed(_:)`` if mdfind execution failed.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Find files containing "budget" in the name
    /// let results = try service.search(
    ///     query: "kMDItemDisplayName == '*budget*'c",
    ///     scope: "~/Documents",
    ///     limit: 10
    /// )
    ///
    /// // Find images larger than 1MB
    /// let largeImages = try service.search(
    ///     query: "kMDItemContentTypeTree == 'public.image' && kMDItemFSSize > 1000000",
    ///     scope: nil,
    ///     limit: nil
    /// )
    /// ```
    func search(query: String, scope: String?, limit: Int?) throws -> [SpotlightService.SearchResult]

    /// Searches files by content type/kind.
    ///
    /// Finds files matching a specific kind (pdf, image, document, etc.). This is a convenience
    /// method that builds the appropriate Spotlight query internally.
    ///
    /// - Parameters:
    ///   - kind: File kind string (e.g., "pdf", "image", "document", "video").
    ///   - scope: Optional directory to limit search scope.
    ///   - limit: Optional maximum number of results.
    /// - Returns: Array of ``SpotlightService/SearchResult`` objects.
    /// - Throws: ``SpotlightError/searchFailed(_:)`` if search failed.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Find all PDFs in Downloads
    /// let pdfs = try service.searchByKind(
    ///     kind: "pdf",
    ///     scope: "~/Downloads",
    ///     limit: 50
    /// )
    ///
    /// // Find all images
    /// let images = try service.searchByKind(
    ///     kind: "image",
    ///     scope: nil,
    ///     limit: nil
    /// )
    /// ```
    ///
    /// ## Supported Kinds
    ///
    /// Common kinds include: pdf, image, video, audio, document, presentation, spreadsheet
    func searchByKind(kind: String, scope: String?, limit: Int?) throws -> [SpotlightService.SearchResult]

    /// Searches for files modified within a time range.
    ///
    /// Finds files that have been modified within the specified number of days.
    ///
    /// - Parameters:
    ///   - days: Number of days to look back from today.
    ///   - scope: Optional directory to limit search scope.
    ///   - limit: Optional maximum number of results.
    /// - Returns: Array of ``SpotlightService/SearchResult`` objects sorted by modification date.
    /// - Throws: ``SpotlightError/searchFailed(_:)`` if search failed.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Find files modified in the last week
    /// let recent = try service.searchModified(
    ///     days: 7,
    ///     scope: "~/Documents",
    ///     limit: 100
    /// )
    /// for result in recent {
    ///     print("\(result.path) - modified \(result.modificationDate)")
    /// }
    /// ```
    func searchModified(days: Int, scope: String?, limit: Int?) throws -> [SpotlightService.SearchResult]

    // MARK: - Metadata

    /// Retrieves Spotlight metadata for a file.
    ///
    /// Queries all available Spotlight metadata attributes for the specified file using `mdls`.
    /// Returns comprehensive metadata including dates, file type, size, and content-specific
    /// attributes.
    ///
    /// - Parameter path: Absolute or relative path to the file.
    /// - Returns: ``SpotlightService/FileMetadata`` object with all metadata attributes.
    /// - Throws:
    ///   - ``SpotlightError/fileNotFound(_:)`` if file doesn't exist.
    ///   - ``SpotlightError/searchFailed(_:)`` if mdls execution failed.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let metadata = try service.getMetadata(path: "~/Documents/report.pdf")
    /// print("Display name: \(metadata.displayName)")
    /// print("Size: \(metadata.fileSize) bytes")
    /// print("Created: \(metadata.creationDate)")
    /// print("Content type: \(metadata.contentType)")
    /// print("Kind: \(metadata.kind)")
    /// ```
    func getMetadata(path: String) throws -> SpotlightService.FileMetadata
}
