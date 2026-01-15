import Foundation

/// Protocol for Safari service operations
protocol SafariServiceProtocol {
    func getReadingList() throws -> [ReadingListItem]
    func addToReadingList(url: String, title: String?) throws
    func getBookmarks() throws -> [Bookmark]
    func getOpenTabs() throws -> [SafariTab]
}
