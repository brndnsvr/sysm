import Foundation

/// Protocol defining Finder tags service operations using extended attributes and mdfind.
///
/// Implementations provide access to macOS Finder tags (color labels),
/// supporting read/write of tags and search by tag name.
protocol TagsServiceProtocol {
    /// Retrieves tags assigned to a file.
    /// - Parameter path: Path to the file.
    /// - Returns: Array of Finder tags.
    func getTags(path: String) throws -> [TagsService.FinderTag]

    /// Sets tags on a file, replacing existing tags.
    /// - Parameters:
    ///   - path: Path to the file.
    ///   - tags: Tags to set.
    func setTags(path: String, tags: [TagsService.FinderTag]) throws

    /// Adds a single tag to a file.
    /// - Parameters:
    ///   - path: Path to the file.
    ///   - name: Tag name.
    ///   - color: Tag color code (0-7).
    func addTag(path: String, name: String, color: Int) throws

    /// Removes a tag from a file.
    /// - Parameters:
    ///   - path: Path to the file.
    ///   - name: Tag name to remove.
    func removeTag(path: String, name: String) throws

    /// Finds files with a specific tag.
    /// - Parameters:
    ///   - name: Tag name to search for.
    ///   - scope: Optional directory to limit search scope.
    /// - Returns: Array of file paths with the tag.
    func findByTag(name: String, scope: String?) throws -> [String]
}
