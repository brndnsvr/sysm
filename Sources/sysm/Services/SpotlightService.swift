import Foundation

struct SpotlightService {
    private let mdfindPath = "/usr/bin/mdfind"
    private let mdlsPath = "/usr/bin/mdls"

    // MARK: - Search Result Model

    struct SearchResult: Codable {
        let path: String
        let name: String
        let kind: String?

        init(path: String, kind: String? = nil) {
            self.path = path
            self.name = URL(fileURLWithPath: path).lastPathComponent
            self.kind = kind
        }

        func formatted() -> String {
            if let kind = kind {
                return "\(name) [\(kind)]\n    \(path)"
            }
            return "\(name)\n    \(path)"
        }
    }

    // MARK: - Metadata Model

    struct FileMetadata: Codable {
        let path: String
        let attributes: [String: String]

        func formatted() -> String {
            var lines = ["Metadata for \(path):"]
            for (key, value) in attributes.sorted(by: { $0.key < $1.key }) {
                let displayKey = key.replacingOccurrences(of: "kMDItem", with: "")
                lines.append("  \(displayKey): \(value)")
            }
            return lines.joined(separator: "\n")
        }
    }

    // MARK: - Search Operations

    func search(query: String, scope: String? = nil, limit: Int? = nil) throws -> [SearchResult] {
        var args: [String] = []

        if let scope = scope {
            args.append(contentsOf: ["-onlyin", scope])
        }

        args.append(query)

        let paths = try runMdfind(args, limit: limit)
        return paths.map { SearchResult(path: $0) }
    }

    func searchByKind(kind: String, scope: String? = nil, limit: Int? = nil) throws -> [SearchResult] {
        let kindMap: [String: String] = [
            "pdf": "PDF Document",
            "image": "Image",
            "video": "Video",
            "audio": "Audio",
            "document": "Document",
            "folder": "Folder",
            "application": "Application",
            "archive": "Archive",
            "presentation": "Presentation",
            "spreadsheet": "Spreadsheet",
            "email": "Email Message",
            "contact": "Contact",
            "calendar": "Calendar Event",
        ]

        let kindValue = kindMap[kind.lowercased()] ?? kind

        var args: [String] = []

        if let scope = scope {
            args.append(contentsOf: ["-onlyin", scope])
        }

        args.append("kMDItemKind == '\(kindValue)'")

        let paths = try runMdfind(args, limit: limit)
        return paths.map { SearchResult(path: $0, kind: kindValue) }
    }

    func searchModified(days: Int, scope: String? = nil, limit: Int? = nil) throws -> [SearchResult] {
        var args: [String] = []

        if let scope = scope {
            args.append(contentsOf: ["-onlyin", scope])
        }

        args.append("kMDItemContentModificationDate >= $time.today(-\(days)d)")

        let paths = try runMdfind(args, limit: limit)
        return paths.map { SearchResult(path: $0) }
    }

    // MARK: - Metadata Operations

    func getMetadata(path: String) throws -> FileMetadata {
        let expandedPath = NSString(string: path).expandingTildeInPath

        guard FileManager.default.fileExists(atPath: expandedPath) else {
            throw SpotlightError.fileNotFound(path)
        }

        let output = try runMdls([expandedPath])
        let attributes = parseMetadata(output)

        return FileMetadata(path: expandedPath, attributes: attributes)
    }

    // MARK: - Private Helpers

    private func runMdfind(_ arguments: [String], limit: Int? = nil) throws -> [String] {
        guard FileManager.default.fileExists(atPath: mdfindPath) else {
            throw SpotlightError.mdfindNotFound
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
            throw SpotlightError.searchFailed(errorMessage.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        let output = String(data: outputData, encoding: .utf8) ?? ""
        var results = output.components(separatedBy: "\n").filter { !$0.isEmpty }

        if let limit = limit, results.count > limit {
            results = Array(results.prefix(limit))
        }

        return results
    }

    private func runMdls(_ arguments: [String]) throws -> String {
        guard FileManager.default.fileExists(atPath: mdlsPath) else {
            throw SpotlightError.mdlsNotFound
        }

        let task = Process()
        task.executableURL = URL(fileURLWithPath: mdlsPath)
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
            throw SpotlightError.metadataFailed(errorMessage.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        return String(data: outputData, encoding: .utf8) ?? ""
    }

    private func parseMetadata(_ output: String) -> [String: String] {
        var attributes: [String: String] = [:]

        for line in output.components(separatedBy: "\n") {
            let parts = line.components(separatedBy: " = ")
            if parts.count == 2 {
                let key = parts[0].trimmingCharacters(in: .whitespaces)
                var value = parts[1].trimmingCharacters(in: .whitespaces)

                // Skip null values
                if value == "(null)" { continue }

                // Clean up quoted strings
                if value.hasPrefix("\"") && value.hasSuffix("\"") {
                    value = String(value.dropFirst().dropLast())
                }

                // Clean up parenthesized values
                if value.hasPrefix("(") && value.hasSuffix(")") {
                    value = String(value.dropFirst().dropLast())
                        .trimmingCharacters(in: .whitespaces)
                }

                attributes[key] = value
            }
        }

        return attributes
    }
}

enum SpotlightError: LocalizedError {
    case mdfindNotFound
    case mdlsNotFound
    case fileNotFound(String)
    case searchFailed(String)
    case metadataFailed(String)

    var errorDescription: String? {
        switch self {
        case .mdfindNotFound:
            return "mdfind not found at /usr/bin/mdfind"
        case .mdlsNotFound:
            return "mdls not found at /usr/bin/mdls"
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .searchFailed(let message):
            return "Search failed: \(message)"
        case .metadataFailed(let message):
            return "Metadata retrieval failed: \(message)"
        }
    }
}
