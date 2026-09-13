import Foundation

public struct TagsService: TagsServiceProtocol {
    private let tagAttribute = "com.apple.metadata:_kMDItemUserTags"
    private let mdfindPath = "/usr/bin/mdfind"

    private var appleScript: any AppleScriptRunnerProtocol { Services.appleScriptRunner() }

    public init() {}

    // MARK: - Tag Model

    public struct FinderTag: Codable, Equatable, Sendable {
        public let name: String
        public let color: Int

        public init(name: String, color: Int) {
            self.name = name
            self.color = color
        }

        /// Finder's label colors, indexed by the number a tag stores.
        ///
        /// The same order as `NSWorkspace.fileLabels`. sysm used to name 1
        /// through 7 Red to Grey, so "--color 1" wrote a gray tag while
        /// printing "Red".
        public static let colorNames = ["None", "Gray", "Green", "Purple", "Blue", "Yellow", "Red", "Orange"]

        public var colorName: String {
            Self.colorNames.indices.contains(color) ? Self.colorNames[color] : "None"
        }

        /// Finder's color number for a name ("red", "grey") or a number ("6").
        ///
        /// - Returns: The color number, or nil if the input names no Finder color.
        public static func colorCode(from input: String) -> Int? {
            let text = input.trimmingCharacters(in: .whitespaces).lowercased()
            if let number = Int(text) {
                return colorNames.indices.contains(number) ? number : nil
            }
            if text == "grey" {
                return 1
            }
            return colorNames.firstIndex { $0.lowercased() == text }
        }

        public func formatted() -> String {
            if color == 0 {
                return name
            }
            return "\(name) (\(colorName))"
        }
    }

    // MARK: - Read Tags

    public func getTags(path: String) throws -> [FinderTag] {
        let url = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: path) else {
            throw TagsError.fileNotFound(path)
        }

        // XATTR_NOFOLLOW: a symlink's tags belong to the link, as in Finder.
        // Following it read and wrote tags on whatever the link pointed at.
        let size = getxattr(url.path, tagAttribute, nil, 0, 0, XATTR_NOFOLLOW)
        if size < 0 {
            // No tags attribute - return empty
            return []
        }

        var data = [UInt8](repeating: 0, count: size)
        let result = getxattr(url.path, tagAttribute, &data, size, 0, XATTR_NOFOLLOW)
        if result < 0 {
            return []
        }

        // Parse binary plist
        let plistData = Data(data)
        guard let plist = try? PropertyListSerialization.propertyList(
            from: plistData,
            options: [],
            format: nil
        ) as? [String] else {
            return []
        }

        return plist.compactMap { parseTagString($0) }
    }

    // MARK: - Write Tags

    public func setTags(path: String, tags: [FinderTag]) throws {
        let url = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: path) else {
            throw TagsError.fileNotFound(path)
        }

        let tagStrings = tags.map { formatTagString($0) }

        let plistData = try PropertyListSerialization.data(
            fromPropertyList: tagStrings,
            format: .binary,
            options: 0
        )

        let result = plistData.withUnsafeBytes { bytes in
            setxattr(url.path, tagAttribute, bytes.baseAddress, plistData.count, 0, XATTR_NOFOLLOW)
        }

        if result < 0 {
            throw TagsError.writeFailed(path, String(cString: strerror(errno)))
        }
    }

    public func addTag(path: String, name: String, color: Int = 0) throws {
        var tags = try getTags(path: path)
        let newTag = FinderTag(name: name, color: color)

        // Don't add duplicate
        if !tags.contains(where: { $0.name == name }) {
            tags.append(newTag)
            try setTags(path: path, tags: tags)
        }
    }

    public func removeTag(path: String, name: String) throws {
        var tags = try getTags(path: path)
        tags.removeAll { $0.name == name }
        try setTags(path: path, tags: tags)
    }

    // MARK: - Find Files by Tag

    public func findByTag(name: String, scope: String? = nil) throws -> [String] {
        let escapedName = appleScript.escapeMdfind(name)
        var args = ["kMDItemUserTags == '\(escapedName)'"]
        if let scope = scope {
            args.insert("-onlyin", at: 0)
            args.insert(scope, at: 1)
        }

        return try runMdfind(args)
    }

    // MARK: - Private Helpers

    private func parseTagString(_ string: String) -> FinderTag? {
        let parts = string.components(separatedBy: "\n")
        let name = parts[0]
        let color = parts.count > 1 ? Int(parts[1]) ?? 0 : 0
        return FinderTag(name: name, color: color)
    }

    private func formatTagString(_ tag: FinderTag) -> String {
        return "\(tag.name)\n\(tag.color)"
    }

    private func runMdfind(_ arguments: [String]) throws -> [String] {
        do {
            let output = try Shell.run(mdfindPath, args: arguments)
            return output.components(separatedBy: "\n").filter { !$0.isEmpty }
        } catch Shell.Error.commandNotFound {
            throw TagsError.mdfindNotFound
        } catch Shell.Error.executionFailed(_, let stderr) {
            throw TagsError.searchFailed(stderr)
        }
    }
}

public enum TagsError: LocalizedError {
    case fileNotFound(String)
    case writeFailed(String, String)
    case mdfindNotFound
    case searchFailed(String)
    case invalidColor(String)

    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .writeFailed(let path, let reason):
            return "Failed to write tags to '\(path)': \(reason)"
        case .mdfindNotFound:
            return "mdfind not found at /usr/bin/mdfind"
        case .searchFailed(let message):
            return "Search failed: \(message)"
        case .invalidColor(let color):
            return "Invalid color '\(color)'. Use a name or number: none (0), gray (1), green (2), purple (3), blue (4), yellow (5), red (6), orange (7)"
        }
    }
}
