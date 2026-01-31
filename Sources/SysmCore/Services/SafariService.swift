import Foundation

public struct SafariService: SafariServiceProtocol {
    private let bookmarksPath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Safari/Bookmarks.plist")

    private var appleScript: any AppleScriptRunnerProtocol { Services.appleScriptRunner() }

    public init() {}

    // MARK: - Reading List

    public func getReadingList() throws -> [ReadingListItem] {
        let plist = try loadBookmarksPlist()
        guard let children = plist["Children"] as? [[String: Any]] else {
            return []
        }

        // Find the Reading List folder (Title = "com.apple.ReadingList")
        for child in children {
            if let title = child["Title"] as? String, title == "com.apple.ReadingList" {
                return extractReadingListItems(from: child)
            }
        }

        return []
    }

    public func addToReadingList(url: String, title: String? = nil) throws {
        // Use AppleScript to add to reading list since plist is read-only
        let displayTitle = title ?? url
        let script = """
        tell application "Safari"
            add reading list item "\(escapeForAppleScript(url))" with title "\(escapeForAppleScript(displayTitle))"
        end tell
        """
        _ = try runAppleScript(script)
    }

    // MARK: - Bookmarks

    public func getBookmarks() throws -> [Bookmark] {
        let plist = try loadBookmarksPlist()
        guard let children = plist["Children"] as? [[String: Any]] else {
            return []
        }

        var bookmarks: [Bookmark] = []

        // Find the BookmarksBar and BookmarksMenu
        for child in children {
            let type = child["WebBookmarkType"] as? String ?? ""
            let title = child["Title"] as? String ?? ""

            // Skip special items like History, Reading List
            if type == "WebBookmarkTypeProxy" { continue }
            if title == "com.apple.ReadingList" { continue }

            bookmarks.append(contentsOf: extractBookmarks(from: child, path: []))
        }

        return bookmarks
    }

    // MARK: - Tabs

    public func getOpenTabs() throws -> [SafariTab] {
        let script = """
        tell application "Safari"
            set tabList to ""
            set windowIndex to 0
            repeat with w in windows
                set windowIndex to windowIndex + 1
                set tabIndex to 0
                repeat with t in tabs of w
                    set tabIndex to tabIndex + 1
                    set tabList to tabList & windowIndex & "|||" & tabIndex & "|||" & (URL of t) & "|||" & (name of t) & "###"
                end repeat
            end repeat
            return tabList
        end tell
        """

        let result = try runAppleScript(script)
        if result.isEmpty { return [] }

        return result.components(separatedBy: "###").compactMap { item -> SafariTab? in
            let parts = item.components(separatedBy: "|||")
            guard parts.count >= 4,
                  let windowIndex = Int(parts[0]),
                  let tabIndex = Int(parts[1]) else { return nil }

            return SafariTab(
                windowIndex: windowIndex,
                tabIndex: tabIndex,
                url: parts[2],
                title: parts[3]
            )
        }
    }

    // MARK: - Private Helpers

    private func loadBookmarksPlist() throws -> [String: Any] {
        guard FileManager.default.fileExists(atPath: bookmarksPath.path) else {
            throw SafariError.bookmarksNotFound
        }

        let data = try Data(contentsOf: bookmarksPath)
        guard let plist = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            throw SafariError.invalidPlist
        }

        return plist
    }

    private func extractReadingListItems(from folder: [String: Any]) -> [ReadingListItem] {
        guard let children = folder["Children"] as? [[String: Any]] else {
            return []
        }

        var items: [ReadingListItem] = []

        for child in children {
            let type = child["WebBookmarkType"] as? String ?? ""

            if type == "WebBookmarkTypeLeaf" {
                if let urlString = child["URLString"] as? String {
                    let uriDict = child["URIDictionary"] as? [String: Any]
                    let title = uriDict?["title"] as? String ?? urlString

                    // Check for preview text if available
                    let readingList = child["ReadingList"] as? [String: Any]
                    let preview = readingList?["PreviewText"] as? String
                    let dateAdded = readingList?["DateAdded"] as? Date

                    items.append(ReadingListItem(
                        title: title,
                        url: urlString,
                        preview: preview,
                        dateAdded: dateAdded
                    ))
                }
            } else if type == "WebBookmarkTypeList" {
                // Recurse into subfolders
                items.append(contentsOf: extractReadingListItems(from: child))
            }
        }

        return items
    }

    private func extractBookmarks(from folder: [String: Any], path: [String]) -> [Bookmark] {
        let type = folder["WebBookmarkType"] as? String ?? ""
        let title = folder["Title"] as? String ?? ""

        var bookmarks: [Bookmark] = []

        if type == "WebBookmarkTypeLeaf" {
            if let urlString = folder["URLString"] as? String {
                let uriDict = folder["URIDictionary"] as? [String: Any]
                let displayTitle = uriDict?["title"] as? String ?? title

                bookmarks.append(Bookmark(
                    title: displayTitle,
                    url: urlString,
                    folder: path.joined(separator: " > ")
                ))
            }
        } else if type == "WebBookmarkTypeList" {
            guard let children = folder["Children"] as? [[String: Any]] else {
                return bookmarks
            }

            let newPath = title.isEmpty ? path : path + [title]

            for child in children {
                bookmarks.append(contentsOf: extractBookmarks(from: child, path: newPath))
            }
        }

        return bookmarks
    }

    private func runAppleScript(_ script: String) throws -> String {
        do {
            return try appleScript.run(script, identifier: "safari")
        } catch AppleScriptError.executionFailed(let message) {
            throw SafariError.appleScriptError(message)
        }
    }

    private func escapeForAppleScript(_ string: String) -> String {
        appleScript.escape(string)
    }
}

// MARK: - Models

public struct ReadingListItem: Codable {
    public let title: String
    public let url: String
    public let preview: String?
    public let dateAdded: Date?
}

public struct Bookmark: Codable {
    public let title: String
    public let url: String
    public let folder: String
}

public struct SafariTab: Codable {
    public let windowIndex: Int
    public let tabIndex: Int
    public let url: String
    public let title: String
}

// MARK: - Errors

public enum SafariError: LocalizedError {
    case bookmarksNotFound
    case invalidPlist
    case appleScriptError(String)
    case safariNotRunning

    public var errorDescription: String? {
        switch self {
        case .bookmarksNotFound:
            return "Safari bookmarks file not found"
        case .invalidPlist:
            return "Could not parse Safari bookmarks plist"
        case .appleScriptError(let message):
            return "AppleScript error: \(message)"
        case .safariNotRunning:
            return "Safari is not running"
        }
    }
}
