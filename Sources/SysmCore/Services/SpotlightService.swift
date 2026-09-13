import Foundation
import UniformTypeIdentifiers

public struct SpotlightService: SpotlightServiceProtocol {
    private let mdfindPath = "/usr/bin/mdfind"
    private let mdlsPath = "/usr/bin/mdls"

    private var appleScript: any AppleScriptRunnerProtocol { Services.appleScriptRunner() }

    public init() {}

    // MARK: - Search Result Model

    public struct SearchResult: Codable, Sendable {
        public let path: String
        public let name: String
        public let kind: String?

        public init(path: String, kind: String? = nil) {
            self.path = path
            self.name = URL(fileURLWithPath: path).lastPathComponent
            self.kind = kind
        }

        public func formatted() -> String {
            if let kind = kind {
                return "\(name) [\(kind)]\n    \(path)"
            }
            return "\(name)\n    \(path)"
        }
    }

    // MARK: - Metadata Model

    public struct FileMetadata: Codable, Sendable {
        public let path: String
        public let attributes: [String: String]

        public func formatted() -> String {
            var lines = ["Metadata for \(path):"]
            for (key, value) in attributes.sorted(by: { $0.key < $1.key }) {
                let displayKey = key.replacingOccurrences(of: "kMDItem", with: "")
                lines.append("  \(displayKey): \(value)")
            }
            return lines.joined(separator: "\n")
        }
    }

    // MARK: - Search Operations

    public func search(query: String, scope: String? = nil, limit: Int? = nil) throws -> [SearchResult] {
        var args: [String] = []

        if let scope = scope {
            args.append(contentsOf: ["-onlyin", scope])
        }

        args.append(query)

        let paths = try runMdfind(args, limit: limit)
        return paths.map { SearchResult(path: $0) }
    }

    public func searchByKind(kind: String, scope: String? = nil, limit: Int? = nil) throws -> [SearchResult] {
        guard let contentType = Self.contentType(forKind: kind) else {
            throw SpotlightError.unknownKind(kind)
        }

        var args: [String] = []

        if let scope = scope {
            args.append(contentsOf: ["-onlyin", scope])
        }

        // kMDItemContentTypeTree lists a file's type and every type it conforms
        // to, so public.image matches JPEG, PNG, and HEIC alike, in any language.
        let escapedType = appleScript.escapeMdfind(contentType)
        args.append("kMDItemContentTypeTree == '\(escapedType)'")

        let label = UTType(contentType)?.localizedDescription ?? contentType
        let paths = try runMdfind(args, limit: limit)
        return paths.map { SearchResult(path: $0, kind: label) }
    }

    /// Kind names sysm understands, mapped to the content types they search for.
    static let contentTypesByKind: [String: String] = [
        "pdf": UTType.pdf.identifier,
        "image": UTType.image.identifier,
        "video": UTType.movie.identifier,
        "audio": UTType.audio.identifier,
        "document": UTType.compositeContent.identifier,
        "text": UTType.text.identifier,
        "folder": UTType.folder.identifier,
        "application": UTType.application.identifier,
        "archive": UTType.archive.identifier,
        "presentation": UTType.presentation.identifier,
        "spreadsheet": UTType.spreadsheet.identifier,
        "email": UTType.emailMessage.identifier,
        "contact": UTType.contact.identifier,
        "calendar": UTType.calendarEvent.identifier,
    ]

    /// The content type to search for: a kind name from ``contentTypesByKind``,
    /// a type identifier ("public.heic"), or a filename extension ("docx").
    ///
    /// Kinds used to match kMDItemKind, the kind text Finder shows, which
    /// changes with the system language and did not even match English
    /// systems ("PDF Document" found no PDFs).
    static func contentType(forKind kind: String) -> String? {
        let key = kind.lowercased()
        if let mapped = contentTypesByKind[key] {
            return mapped
        }
        if let type = UTType(kind), type.isDeclared {
            return type.identifier
        }
        if let type = UTType(filenameExtension: key), type.isDeclared {
            return type.identifier
        }
        return nil
    }

    public func searchModified(days: Int, scope: String? = nil, limit: Int? = nil) throws -> [SearchResult] {
        var args: [String] = []

        if let scope = scope {
            args.append(contentsOf: ["-onlyin", scope])
        }

        args.append("kMDItemContentModificationDate >= $time.today(-\(days)d)")

        let paths = try runMdfind(args, limit: limit)
        return paths.map { SearchResult(path: $0) }
    }

    // MARK: - Metadata Operations

    public func getMetadata(path: String) throws -> FileMetadata {
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

public enum SpotlightError: LocalizedError {
    case mdfindNotFound
    case mdlsNotFound
    case fileNotFound(String)
    case searchFailed(String)
    case metadataFailed(String)
    case unknownKind(String)

    public var errorDescription: String? {
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
        case .unknownKind(let kind):
            let names = SpotlightService.contentTypesByKind.keys.sorted().joined(separator: ", ")
            return "Unknown kind '\(kind)'. Use one of \(names), a content type such as public.heic, or a file extension such as docx"
        }
    }
}
