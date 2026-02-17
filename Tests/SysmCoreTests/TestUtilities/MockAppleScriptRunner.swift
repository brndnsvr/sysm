import Foundation
@testable import SysmCore

/// Mock AppleScriptRunner for testing services that depend on AppleScript execution.
///
/// Configure `responses` with expected script identifiers as keys and return values.
/// Set `errorToThrow` to simulate AppleScript failures.
final class MockAppleScriptRunner: AppleScriptRunnerProtocol, @unchecked Sendable {
    /// Responses keyed by script identifier or content substring.
    var responses: [String: String] = [:]

    /// Default response when no matching key is found.
    var defaultResponse: String = ""

    /// If set, all run() calls throw this error.
    var errorToThrow: Error?

    /// Records all scripts that were executed.
    var executedScripts: [(script: String, identifier: String)] = []

    func escape(_ string: String) -> String {
        string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
    }

    func escapeMdfind(_ string: String) -> String {
        string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
    }

    func run(_ script: String, identifier: String) throws -> String {
        executedScripts.append((script: script, identifier: identifier))

        if let error = errorToThrow {
            throw error
        }

        // Check responses by identifier first
        if let response = responses[identifier] {
            return response
        }

        // Check if any response key is contained in the script
        for (key, response) in responses {
            if script.contains(key) {
                return response
            }
        }

        return defaultResponse
    }

    func runWithRetry(_ script: String, identifier: String, maxRetries: Int, initialDelay: TimeInterval) throws -> String {
        return try run(script, identifier: identifier)
    }
}
