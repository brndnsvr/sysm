import Foundation

public struct BooksService: BooksServiceProtocol {
    public init() {}

    public func listBooks() throws -> [BookInfo] {
        // Books.app stores data in ~/Library/Containers/com.apple.BKAgentService/Data/Documents/iBooks/
        // Use Spotlight to find books
        let output = try Shell.run("/usr/bin/mdfind", args: [
            "-onlyin", NSHomeDirectory(),
            "kMDItemContentType == 'com.apple.ibooks.epub' || kMDItemContentType == 'com.adobe.pdf' || kMDItemContentType == 'org.idpf.epub-container'",
        ])

        guard !output.isEmpty else { return [] }

        return output.split(separator: "\n").compactMap { line in
            let path = String(line).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !path.isEmpty else { return nil }

            let url = URL(fileURLWithPath: path)
            let title = url.deletingPathExtension().lastPathComponent

            // Try to get author from Spotlight metadata
            var author: String?
            if let mdls = try? Shell.run("/usr/bin/mdls", args: ["-name", "kMDItemAuthors", path]) {
                let lines = mdls.split(separator: "\n")
                for mdLine in lines {
                    let trimmed = String(mdLine).trimmingCharacters(in: .whitespaces)
                    if trimmed.hasPrefix("\"") {
                        author = trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                        break
                    }
                }
            }

            return BookInfo(title: title, author: author, path: path)
        }
    }

    public func listCollections() throws -> [BookCollection] {
        // Books collections are stored in the BKLibrary SQLite database
        // which is hard to access directly. Use Spotlight to find collection folders.
        let booksPath = "\(NSHomeDirectory())/Library/Mobile Documents/iCloud~com~apple~iBooks/Documents"
        let fm = FileManager.default

        guard fm.fileExists(atPath: booksPath) else {
            return []
        }

        let contents = try fm.contentsOfDirectory(atPath: booksPath)
        return contents.compactMap { name in
            var isDir: ObjCBool = false
            let fullPath = "\(booksPath)/\(name)"
            guard fm.fileExists(atPath: fullPath, isDirectory: &isDir), isDir.boolValue else {
                return nil
            }
            let bookCount = (try? fm.contentsOfDirectory(atPath: fullPath))?.count ?? 0
            return BookCollection(name: name, bookCount: bookCount)
        }
    }
}
