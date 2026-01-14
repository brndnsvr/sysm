import Foundation

struct ShortcutsService {
    private let shortcutsPath = "/usr/bin/shortcuts"

    func list() throws -> [String] {
        let result = try runShortcuts(["list"])
        if result.isEmpty { return [] }
        return result.components(separatedBy: "\n").filter { !$0.isEmpty }
    }

    func run(name: String, input: String? = nil) throws -> String {
        var args = ["run", name]

        if let input = input {
            args.append(contentsOf: ["--input-path", "-"])
            return try runShortcuts(args, stdin: input)
        }

        return try runShortcuts(args)
    }

    private func runShortcuts(_ arguments: [String], stdin: String? = nil) throws -> String {
        guard FileManager.default.fileExists(atPath: shortcutsPath) else {
            throw ShortcutsError.shortcutsNotFound
        }

        let task = Process()
        task.executableURL = URL(fileURLWithPath: shortcutsPath)
        task.arguments = arguments

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = errorPipe

        if let stdin = stdin {
            let inputPipe = Pipe()
            task.standardInput = inputPipe
            try task.run()
            inputPipe.fileHandleForWriting.write(stdin.data(using: .utf8)!)
            inputPipe.fileHandleForWriting.closeFile()
        } else {
            try task.run()
        }

        task.waitUntilExit()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

        if task.terminationStatus != 0 {
            let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            if errorMessage.contains("not found") || errorMessage.contains("no shortcut") {
                throw ShortcutsError.shortcutNotFound(arguments.count > 1 ? arguments[1] : "unknown")
            }
            throw ShortcutsError.executionFailed(errorMessage.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        return String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}

enum ShortcutsError: LocalizedError {
    case shortcutsNotFound
    case shortcutNotFound(String)
    case executionFailed(String)

    var errorDescription: String? {
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
