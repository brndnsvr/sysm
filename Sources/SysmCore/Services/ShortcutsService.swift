import Foundation

public struct ShortcutsService: ShortcutsServiceProtocol {
    private let shortcutsPath = "/usr/bin/shortcuts"

    public func list() throws -> [String] {
        let result = try runShortcuts(["list"])
        if result.isEmpty { return [] }
        return result.components(separatedBy: "\n").filter { !$0.isEmpty }
    }

    public func run(name: String, input: String? = nil) throws -> String {
        var args = ["run", name]

        if let input = input {
            args.append(contentsOf: ["--input-path", "-"])
            return try runShortcuts(args, stdin: input)
        }

        return try runShortcuts(args)
    }

    private func runShortcuts(_ arguments: [String], stdin: String? = nil) throws -> String {
        do {
            return try Shell.run(shortcutsPath, args: arguments, stdin: stdin)
        } catch Shell.Error.commandNotFound {
            throw ShortcutsError.shortcutsNotFound
        } catch Shell.Error.executionFailed(_, let stderr) {
            if stderr.contains("not found") || stderr.contains("no shortcut") {
                throw ShortcutsError.shortcutNotFound(arguments.count > 1 ? arguments[1] : "unknown")
            }
            throw ShortcutsError.executionFailed(stderr)
        }
    }
}

public enum ShortcutsError: LocalizedError {
    case shortcutsNotFound
    case shortcutNotFound(String)
    case executionFailed(String)

    public var errorDescription: String? {
        switch self {
        case .shortcutsNotFound:
            return "shortcuts CLI not found at /usr/bin/shortcuts"
        case .shortcutNotFound(let name):
            return "Shortcut '\(name)' not found"
        case .executionFailed(let message):
            return "Shortcut execution failed: \(message)"
        }
    }
}
