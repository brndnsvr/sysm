import Foundation

/// Protocol defining Safari service operations for accessing Safari data via AppleScript.
///
/// Implementations provide read access to Safari's reading list, bookmarks, and open tabs.
protocol SafariServiceProtocol {
    /// Retrieves all reading list items.
    /// - Returns: Array of reading list items.
    func getReadingList() throws -> [ReadingListItem]

    /// Adds a URL to the reading list.
    /// - Parameters:
    ///   - url: The URL to add.
    ///   - title: Optional title for the item.
    func addToReadingList(url: String, title: String?) throws

    /// Retrieves all bookmarks.
    /// - Returns: Array of bookmarks.
    func getBookmarks() throws -> [Bookmark]

    /// Retrieves all currently open tabs.
    /// - Returns: Array of open tabs.
    func getOpenTabs() throws -> [SafariTab]
}
