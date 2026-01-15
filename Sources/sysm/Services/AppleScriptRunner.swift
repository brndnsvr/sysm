import Foundation

/// Shared utility for AppleScript execution with proper escaping
struct AppleScriptRunner {

    /// Escapes a string for safe interpolation into AppleScript
    /// Prevents injection attacks by escaping special characters
    static func escape(_ string: String) -> String {
        string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
    }

    /// Escapes a string for safe use in mdfind queries (single-quoted strings)
    /// Prevents injection by escaping single quotes and backslashes
    static func escapeMdfind(_ string: String) -> String {
        string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
    }

    /// Runs AppleScript and returns output
    /// - Parameters:
    ///   - script: The AppleScript to execute
    ///   - identifier: Optional identifier for temp file naming (for debugging)
    /// - Returns: The script output as a string
    /// - Throws: AppleScriptError.executionFailed if script fails
    static func run(_ script: String, identifier: String = "generic") throws -> String {
        let tempFile = FileManager.default.temporaryDirectory
            .appendingPathComponent("sysm-\(identifier)-\(UUID().uuidString).scpt")
        try script.write(to: tempFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempFile) }

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        task.arguments = [tempFile.path]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = errorPipe

        try task.run()
        task.waitUntilExit()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

        if task.terminationStatus != 0 {
            let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw AppleScriptError.executionFailed(errorMessage)
        }

        return String(data: outputData, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}

enum AppleScriptError: LocalizedError {
    case executionFailed(String)

    var errorDescription: String? {
        switch self {
        case .executionFailed(let message):
            return "AppleScript error: \(message)"
        }
    }
}
