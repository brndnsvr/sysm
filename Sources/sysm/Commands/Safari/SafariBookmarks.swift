import ArgumentParser
import Foundation

struct SafariBookmarks: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "bookmarks",
        abstract: "List Safari bookmarks"
    )

    @Option(name: .long, help: "Filter bookmarks by folder name")
    var folder: String?

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.safari()
        var bookmarks = try service.getBookmarks()

        // Filter by folder if specified
        if let folder = folder {
            bookmarks = bookmarks.filter { $0.folder.lowercased().contains(folder.lowercased()) }
        }

        if json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(bookmarks)
            if let jsonString = String(data: data, encoding: .utf8) {
                print(jsonString)
            }
        } else {
            if bookmarks.isEmpty {
                print("No bookmarks found")
            } else {
                print("Bookmarks (\(bookmarks.count)):")

                // Group by folder for readability
                let grouped = Dictionary(grouping: bookmarks) { $0.folder.isEmpty ? "(root)" : $0.folder }
                let sortedFolders = grouped.keys.sorted()

                for folderName in sortedFolders {
                    print("\n  [\(folderName)]")
                    if let folderBookmarks = grouped[folderName] {
                        for bookmark in folderBookmarks {
                            print("    - \(bookmark.title)")
                            print("      \(bookmark.url)")
                        }
                    }
                }
            }
        }
    }
}
