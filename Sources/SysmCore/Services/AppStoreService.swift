import Foundation

public struct AppStoreService: AppStoreServiceProtocol {
    private let masPath: String

    public init() {
        // Check common locations for mas
        if FileManager.default.fileExists(atPath: "/opt/homebrew/bin/mas") {
            self.masPath = "/opt/homebrew/bin/mas"
        } else if FileManager.default.fileExists(atPath: "/usr/local/bin/mas") {
            self.masPath = "/usr/local/bin/mas"
        } else {
            self.masPath = "mas"
        }
    }

    public func isAvailable() -> Bool {
        FileManager.default.fileExists(atPath: masPath)
    }

    public func listInstalled() throws -> [AppStoreApp] {
        let output = try runMas(["list"])
        return parseAppList(output)
    }

    public func listOutdated() throws -> [AppStoreApp] {
        let output = try runMas(["outdated"])
        return parseAppList(output)
    }

    public func search(query: String) throws -> [AppStoreApp] {
        let output = try runMas(["search", query])
        return parseAppList(output)
    }

    public func update(appId: String? = nil) throws -> String {
        if let appId = appId {
            return try runMas(["upgrade", appId])
        } else {
            return try runMas(["upgrade"])
        }
    }

    // MARK: - Private

    private func runMas(_ args: [String]) throws -> String {
        guard isAvailable() else {
            throw AppStoreError.masNotInstalled
        }
        return try Shell.run(masPath, args: args)
    }

    private func parseAppList(_ output: String) -> [AppStoreApp] {
        output.components(separatedBy: "\n").compactMap { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return nil }

            // mas output format: "ID  Name (version)" or "ID  Name version"
            let parts = trimmed.split(separator: " ", maxSplits: 1)
            guard parts.count == 2 else { return nil }

            let id = String(parts[0])
            var rest = String(parts[1]).trimmingCharacters(in: .whitespaces)

            // Extract version if present in parentheses at the end
            var version: String?
            if let parenRange = rest.range(of: #"\(([^)]+)\)$"#, options: .regularExpression) {
                let versionStr = String(rest[parenRange])
                    .trimmingCharacters(in: CharacterSet(charactersIn: "()"))
                version = versionStr
                rest = String(rest[rest.startIndex..<parenRange.lowerBound])
                    .trimmingCharacters(in: .whitespaces)
            }

            return AppStoreApp(id: id, name: rest, version: version)
        }
    }
}

public enum AppStoreError: LocalizedError {
    case masNotInstalled
    case updateFailed(String)

    public var errorDescription: String? {
        switch self {
        case .masNotInstalled:
            return "mas is not installed. Install with: brew install mas"
        case .updateFailed(let msg):
            return "Update failed: \(msg)"
        }
    }
}
