import Foundation

struct SpotlightService: SpotlightServiceProtocol {
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

        let escapedKind = AppleScriptRunner.escapeMdfind(kindValue)
        args.append("kMDItemKind == '\(escapedKind)'")

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
        do {
            let output = try Shell.run(mdfindPath, args: arguments)
            var results = output.components(separatedBy: "\n").filter { !$0.isEmpty }

            if let limit = limit, results.count > limit {
                results = Array(results.prefix(limit))
            }

            return results
        } catch Shell.Error.commandNotFound {
            throw SpotlightError.mdfindNotFound
        } catch Shell.Error.executionFailed(_, let stderr) {
            throw SpotlightError.searchFailed(stderr)
        }
    }

    private func runMdls(_ arguments: [String]) throws -> String {
        do {
            return try Shell.run(mdlsPath, args: arguments)
        } catch Shell.Error.commandNotFound {
            throw SpotlightError.mdlsNotFound
        } catch Shell.Error.executionFailed(_, let stderr) {
            throw SpotlightError.metadataFailed(stderr)
        }
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
