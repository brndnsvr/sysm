import Foundation

struct TagsService {
    private let tagAttribute = "com.apple.metadata:_kMDItemUserTags"
    private let mdfindPath = "/usr/bin/mdfind"

    // MARK: - Tag Model

    struct FinderTag: Codable, Equatable {
        let name: String
        let color: Int

        var colorName: String {
            switch color {
            case 1: return "Red"
            case 2: return "Orange"
            case 3: return "Yellow"
            case 4: return "Green"
            case 5: return "Blue"
            case 6: return "Purple"
            case 7: return "Grey"
            default: return "None"
            }
        }

        func formatted() -> String {
            if color == 0 {
                return name
            }
            return "\(name) (\(colorName))"
        }
    }

    // MARK: - Read Tags

    func getTags(path: String) throws -> [FinderTag] {
        let url = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: path) else {
            throw TagsError.fileNotFound(path)
        }

        let size = getxattr(url.path, tagAttribute, nil, 0, 0, 0)
        if size < 0 {
            // No tags attribute - return empty
            return []
        }

        var data = [UInt8](repeating: 0, count: size)
        let result = getxattr(url.path, tagAttribute, &data, size, 0, 0)
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

    func setTags(path: String, tags: [FinderTag]) throws {
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
            setxattr(url.path, tagAttribute, bytes.baseAddress, plistData.count, 0, 0)
        }

        if result < 0 {
            throw TagsError.writeFailed(path, String(cString: strerror(errno)))
        }
    }

    func addTag(path: String, name: String, color: Int = 0) throws {
        var tags = try getTags(path: path)
        let newTag = FinderTag(name: name, color: color)

        // Don't add duplicate
        if !tags.contains(where: { $0.name == name }) {
            tags.append(newTag)
            try setTags(path: path, tags: tags)
        }
    }

    func removeTag(path: String, name: String) throws {
        var tags = try getTags(path: path)
        tags.removeAll { $0.name == name }
        try setTags(path: path, tags: tags)
    }

    // MARK: - Find Files by Tag

    func findByTag(name: String, scope: String? = nil) throws -> [String] {
        let escapedName = AppleScriptRunner.escapeMdfind(name)
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
        guard FileManager.default.fileExists(atPath: mdfindPath) else {
            throw TagsError.mdfindNotFound
        }

        let task = Process()
        task.executableURL = URL(fileURLWithPath: mdfindPath)
        task.arguments = arguments

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = errorPipe

        try task.run()
        task.waitUntilExit()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()

        if task.terminationStatus != 0 {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw TagsError.searchFailed(errorMessage.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        let output = String(data: outputData, encoding: .utf8) ?? ""
        return output.components(separatedBy: "\n").filter { !$0.isEmpty }
    }
}

enum TagsError: LocalizedError {
    case fileNotFound(String)
    case writeFailed(String, String)
    case mdfindNotFound
    case searchFailed(String)
    case invalidColor(Int)

    var errorDescription: String? {
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
            return "Invalid color code: \(color). Use 0-7 (0=none, 1=red, 2=orange, 3=yellow, 4=green, 5=blue, 6=purple, 7=grey)"
        }
    }
}
