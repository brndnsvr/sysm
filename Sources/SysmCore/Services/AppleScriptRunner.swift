import Foundation

/// Shared utility for AppleScript execution with proper escaping
public struct AppleScriptRunner: AppleScriptRunnerProtocol {

    public init() {}

    // MARK: - Instance Methods (Protocol Conformance)

    /// Escapes a string for safe interpolation into AppleScript.
    /// Prevents injection attacks by escaping special characters.
    public func escape(_ string: String) -> String {
        string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
    }

    /// Escapes a string for safe use in mdfind queries (single-quoted strings).
    /// Prevents injection by escaping single quotes and backslashes.
    public func escapeMdfind(_ string: String) -> String {
        string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
    }

    /// Runs AppleScript and returns output.
    /// - Parameters:
    ///   - script: The AppleScript to execute.
    ///   - identifier: Optional identifier for temp file naming (for debugging).
    /// - Returns: The script output as a string.
    /// - Throws: AppleScriptError.executionFailed if script fails.
    public func run(_ script: String, identifier: String = "generic") throws -> String {
        try executeScript(script, identifier: identifier)
    }

    /// Runs AppleScript with automatic retry on transient failures.
    ///
    /// Retries the script execution with exponential backoff if it fails with a transient error.
    /// Transient errors include timeouts, temporary unavailability, and connection issues.
    ///
    /// - Parameters:
    ///   - script: The AppleScript to execute.
    ///   - identifier: Optional identifier for temp file naming (for debugging).
    ///   - maxRetries: Maximum number of retry attempts. Default is 3.
    ///   - initialDelay: Initial delay in seconds before first retry. Default is 0.5s.
    /// - Returns: The script output as a string.
    /// - Throws: AppleScriptError.executionFailed if script fails after all retries.
    ///
    /// ## Retry Strategy
    ///
    /// - Uses exponential backoff: 0.5s, 1s, 2s, 4s, etc.
    /// - Only retries on transient errors (timeouts, connection issues)
    /// - Permanent errors (syntax errors, access denied) fail immediately
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Retry up to 3 times with exponential backoff
    /// let output = try runner.runWithRetry(script, identifier: "mail-send", maxRetries: 3)
    /// ```
    public func runWithRetry(
        _ script: String,
        identifier: String = "generic",
        maxRetries: Int = 3,
        initialDelay: TimeInterval = 0.5
    ) throws -> String {
        var lastError: Error?
        var delay = initialDelay

        for attempt in 0...maxRetries {
            do {
                return try executeScript(script, identifier: identifier)
            } catch let error as AppleScriptError {
                lastError = error

                // Check if error is retryable
                if !isTransientError(error) {
                    // Permanent error, don't retry
                    throw error
                }

                // Last attempt failed
                if attempt == maxRetries {
                    throw error
                }

                // Wait with exponential backoff
                Thread.sleep(forTimeInterval: delay)
                delay *= 2

                // Log retry attempt (could be enhanced with proper logging)
                #if DEBUG
                print("AppleScript retry attempt \(attempt + 1)/\(maxRetries) after \(delay/2)s delay for \(identifier)")
                #endif
            }
        }

        throw lastError ?? AppleScriptError.executionFailed("Unknown error during retry")
    }

    // MARK: - Private Helpers

    /// Executes an AppleScript and returns output.
    private func executeScript(_ script: String, identifier: String) throws -> String {
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

        // Read stdout and stderr concurrently BEFORE waitUntilExit to avoid
        // pipe buffer deadlocks. If a pipe's buffer fills (~64KB), the process
        // blocks until the buffer is drained. Reading after waitUntilExit would
        // deadlock since waitUntilExit can't return while the process is blocked.
        var outputData = Data()
        var errorData = Data()
        let readGroup = DispatchGroup()

        readGroup.enter()
        DispatchQueue.global().async {
            outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            readGroup.leave()
        }
        errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        readGroup.wait()

        task.waitUntilExit()

        if task.terminationStatus != 0 {
            let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw AppleScriptError.executionFailed(errorMessage)
        }

        return String(data: outputData, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    /// Determines if an AppleScript error is transient and worth retrying.
    private func isTransientError(_ error: AppleScriptError) -> Bool {
        guard case .executionFailed(let message) = error else {
            return false
        }

        let transientIndicators = [
            "timeout",
            "timed out",
            "connection",
            "not running",
            "isn't running",
            "busy",
            "temporary",
            "unavailable",
            "try again"
        ]

        let lowercaseMessage = message.lowercased()
        return transientIndicators.contains { lowercaseMessage.contains($0) }
    }
}

public enum AppleScriptError: LocalizedError {
    case executionFailed(String)

    public var errorDescription: String? {
        switch self {
        case .executionFailed(let message):
            return "AppleScript error: \(message)"
        }
    }
}
