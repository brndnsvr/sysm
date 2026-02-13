import Foundation

/// Protocol defining Safari service operations for accessing Safari data via AppleScript.
///
/// This protocol provides read access to Safari's reading list, bookmarks, and open tabs through
/// AppleScript integration. Supports adding items to the reading list and querying browser state.
///
/// ## Permission Requirements
///
/// Safari integration uses AppleScript and may require:
/// - Automation permission for controlling Safari.app
/// - System Settings > Privacy & Security > Automation
/// - Safari.app must be running for most operations
///
/// ## Usage Example
///
/// ```swift
/// let service = SafariService()
///
/// // Get reading list
/// let readingList = try service.getReadingList()
/// for item in readingList {
///     print("\(item.title ?? "Untitled"): \(item.url)")
/// }
///
/// // Add to reading list
/// try service.addToReadingList(
///     url: "https://example.com/article",
///     title: "Interesting Article"
/// )
///
/// // Get open tabs
/// let tabs = try service.getOpenTabs()
/// for tab in tabs {
///     print("\(tab.title): \(tab.url)")
/// }
/// ```
///
/// ## Thread Safety
///
/// Implementations are marked as `Sendable` and safe to use across actor boundaries.
/// AppleScript operations are synchronous and blocking.
///
/// ## Error Handling
///
/// All methods can throw ``SafariError`` variants:
/// - ``SafariError/safariNotRunning`` - Safari.app is not running
/// - ``SafariError/invalidURL(_:)`` - URL format is invalid
/// - ``SafariError/scriptFailed(_:)`` - AppleScript execution failed
/// - ``SafariError/accessDenied`` - Automation permission not granted
///
public protocol SafariServiceProtocol: Sendable {
    // MARK: - Reading List

    /// Retrieves all reading list items.
    ///
    /// Returns URLs and titles for all items in Safari's Reading List, including both
    /// read and unread items.
    ///
    /// - Returns: Array of ``ReadingListItem`` objects.
    /// - Throws:
    ///   - ``SafariError/safariNotRunning`` if Safari.app is not running.
    ///   - ``SafariError/scriptFailed(_:)`` if AppleScript execution failed.
    func getReadingList() throws -> [ReadingListItem]

    /// Adds a URL to the reading list.
    ///
    /// Adds the specified URL to Safari's Reading List for later reading. The page will
    /// be downloaded for offline access according to Safari's settings.
    ///
    /// - Parameters:
    ///   - url: The URL to add (must be a valid HTTP/HTTPS URL).
    ///   - title: Optional title for the reading list item. If nil, Safari fetches the page title.
    /// - Throws:
    ///   - ``SafariError/safariNotRunning`` if Safari.app is not running.
    ///   - ``SafariError/invalidURL(_:)`` if URL format is invalid.
    ///   - ``SafariError/scriptFailed(_:)`` if operation failed.
    ///
    /// ## Example
    ///
    /// ```swift
    /// try service.addToReadingList(
    ///     url: "https://developer.apple.com/documentation/",
    ///     title: "Apple Documentation"
    /// )
    /// ```
    func addToReadingList(url: String, title: String?) throws

    // MARK: - Bookmarks

    /// Retrieves all bookmarks.
    ///
    /// Returns all bookmarks from Safari, including those in folders. Bookmarks are returned
    /// in a flat list (folder structure is not preserved).
    ///
    /// - Returns: Array of ``Bookmark`` objects.
    /// - Throws:
    ///   - ``SafariError/safariNotRunning`` if Safari.app is not running.
    ///   - ``SafariError/scriptFailed(_:)`` if AppleScript execution failed.
    func getBookmarks() throws -> [Bookmark]

    // MARK: - Tabs

    /// Retrieves all currently open tabs across all Safari windows.
    ///
    /// Returns information about all tabs open in Safari, including their titles and URLs.
    /// Tabs are returned in order by window and tab index.
    ///
    /// - Returns: Array of ``SafariTab`` objects.
    /// - Throws:
    ///   - ``SafariError/safariNotRunning`` if Safari.app is not running.
    ///   - ``SafariError/scriptFailed(_:)`` if AppleScript execution failed.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let tabs = try service.getOpenTabs()
    /// print("You have \(tabs.count) tabs open")
    /// for (index, tab) in tabs.enumerated() {
    ///     print("\(index + 1). \(tab.title)")
    /// }
    /// ```
    func getOpenTabs() throws -> [SafariTab]
}
