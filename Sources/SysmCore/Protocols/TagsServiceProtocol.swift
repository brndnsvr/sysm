import Foundation

/// Protocol defining Finder tags service operations using extended attributes and mdfind.
///
/// This protocol provides access to macOS Finder tags (color labels) through extended attributes
/// (xattrs) and Spotlight. Supports reading, writing, and searching for Finder tags on files.
///
/// ## Finder Tags
///
/// Finder tags are labels with associated colors that help organize files:
/// - Stored as extended attributes (`com.apple.metadata:_kMDItemUserTags`)
/// - Each tag has a name and optional color code (0-7)
/// - Searchable via Spotlight/mdfind
///
/// ## Usage Example
///
/// ```swift
/// let service = TagsService()
///
/// // Get tags from a file
/// let tags = try service.getTags(path: "~/Documents/report.pdf")
/// for tag in tags {
///     print("Tag: \(tag.name), Color: \(tag.color)")
/// }
///
/// // Add a tag
/// try service.addTag(path: "~/Documents/report.pdf", name: "Important", color: 6)
///
/// // Set multiple tags (replaces existing)
/// try service.setTags(
///     path: "~/Documents/report.pdf",
///     tags: [
///         TagsService.FinderTag(name: "Work", color: 2),
///         TagsService.FinderTag(name: "Q1", color: 3)
///     ]
/// )
///
/// // Find files with a tag
/// let workFiles = try service.findByTag(name: "Work", scope: "~/Documents")
/// print("Found \(workFiles.count) files")
/// ```
///
/// ## Thread Safety
///
/// Implementations are marked as `Sendable` and safe to use across actor boundaries.
/// File operations are synchronous.
///
/// ## Error Handling
///
/// Methods can throw ``TagsError`` variants:
/// - ``TagsError/fileNotFound(_:)`` - File doesn't exist
/// - ``TagsError/permissionDenied(_:)`` - Cannot access or modify file
/// - ``TagsError/invalidColor(_:)`` - Color code outside valid range (0-7)
/// - ``TagsError/operationFailed(_:)`` - Extended attribute operation failed
///
public protocol TagsServiceProtocol: Sendable {
    // MARK: - Reading Tags

    /// Retrieves tags assigned to a file.
    ///
    /// Reads Finder tags from the file's extended attributes.
    ///
    /// - Parameter path: Absolute or relative path to the file.
    /// - Returns: Array of ``TagsService/FinderTag`` objects.
    /// - Throws:
    ///   - ``TagsError/fileNotFound(_:)`` if file doesn't exist.
    ///   - ``TagsError/permissionDenied(_:)`` if cannot read file.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let tags = try service.getTags(path: "~/Documents/report.pdf")
    /// if tags.isEmpty {
    ///     print("No tags")
    /// } else {
    ///     print("Tags: \(tags.map { $0.name }.joined(separator: ", "))")
    /// }
    /// ```
    func getTags(path: String) throws -> [TagsService.FinderTag]

    // MARK: - Writing Tags

    /// Sets tags on a file, replacing existing tags.
    ///
    /// Replaces all existing tags with the specified tags. To add tags without removing
    /// existing ones, use ``addTag(path:name:color:)``.
    ///
    /// - Parameters:
    ///   - path: Absolute or relative path to the file.
    ///   - tags: Array of tags to set.
    /// - Throws:
    ///   - ``TagsError/fileNotFound(_:)`` if file doesn't exist.
    ///   - ``TagsError/permissionDenied(_:)`` if cannot modify file.
    ///   - ``TagsError/operationFailed(_:)`` if setting tags failed.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Replace all tags
    /// try service.setTags(
    ///     path: "~/Documents/report.pdf",
    ///     tags: [
    ///         TagsService.FinderTag(name: "Important", color: 6),
    ///         TagsService.FinderTag(name: "Review", color: 1)
    ///     ]
    /// )
    ///
    /// // Clear all tags
    /// try service.setTags(path: "~/Documents/report.pdf", tags: [])
    /// ```
    func setTags(path: String, tags: [TagsService.FinderTag]) throws

    /// Adds a single tag to a file.
    ///
    /// Adds a new tag without removing existing tags. If the tag already exists, it's not duplicated.
    ///
    /// - Parameters:
    ///   - path: Absolute or relative path to the file.
    ///   - name: Tag name.
    ///   - color: Tag color code (0-7): 0=none, 1=gray, 2=green, 3=purple, 4=blue, 5=yellow, 6=red, 7=orange.
    /// - Throws:
    ///   - ``TagsError/fileNotFound(_:)`` if file doesn't exist.
    ///   - ``TagsError/permissionDenied(_:)`` if cannot modify file.
    ///   - ``TagsError/invalidColor(_:)`` if color is outside 0-7 range.
    ///   - ``TagsError/operationFailed(_:)`` if adding tag failed.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Add a red tag
    /// try service.addTag(path: "~/Documents/urgent.pdf", name: "Urgent", color: 6)
    ///
    /// // Add a tag with no color
    /// try service.addTag(path: "~/Documents/file.txt", name: "Draft", color: 0)
    /// ```
    ///
    /// ## Color Codes
    ///
    /// - 0: None (no color)
    /// - 1: Gray
    /// - 2: Green
    /// - 3: Purple
    /// - 4: Blue
    /// - 5: Yellow
    /// - 6: Red
    /// - 7: Orange
    func addTag(path: String, name: String, color: Int) throws

    /// Removes a tag from a file.
    ///
    /// Removes the specified tag by name. Other tags remain unchanged. If the tag doesn't
    /// exist on the file, this is a no-op (doesn't throw an error).
    ///
    /// - Parameters:
    ///   - path: Absolute or relative path to the file.
    ///   - name: Tag name to remove.
    /// - Throws:
    ///   - ``TagsError/fileNotFound(_:)`` if file doesn't exist.
    ///   - ``TagsError/permissionDenied(_:)`` if cannot modify file.
    ///   - ``TagsError/operationFailed(_:)`` if removing tag failed.
    ///
    /// ## Example
    ///
    /// ```swift
    /// try service.removeTag(path: "~/Documents/report.pdf", name: "Draft")
    /// ```
    func removeTag(path: String, name: String) throws

    // MARK: - Search

    /// Finds files with a specific tag.
    ///
    /// Uses Spotlight (mdfind) to search for files tagged with the specified name.
    ///
    /// - Parameters:
    ///   - name: Tag name to search for (case-sensitive).
    ///   - scope: Optional directory to limit search scope. If nil, searches all indexed locations.
    /// - Returns: Array of absolute file paths with the tag.
    /// - Throws: ``TagsError/operationFailed(_:)`` if search failed.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Find all files tagged "Important"
    /// let files = try service.findByTag(name: "Important", scope: nil)
    /// print("Found \(files.count) important files:")
    /// for file in files {
    ///     print("  - \(file)")
    /// }
    ///
    /// // Find tagged files in a specific directory
    /// let workFiles = try service.findByTag(name: "Work", scope: "~/Documents")
    /// ```
    func findByTag(name: String, scope: String?) throws -> [String]
}
