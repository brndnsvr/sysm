import Foundation

/// Protocol defining AppleScript execution operations.
///
/// Implementations handle running AppleScript code with proper escaping
/// to prevent injection attacks.
public protocol AppleScriptRunnerProtocol: Sendable {
    /// Escapes a string for safe interpolation into AppleScript.
    /// - Parameter string: The string to escape.
    /// - Returns: The escaped string safe for AppleScript interpolation.
    func escape(_ string: String) -> String

    /// Escapes a string for safe use in mdfind queries (single-quoted strings).
    /// - Parameter string: The string to escape.
    /// - Returns: The escaped string safe for mdfind queries.
    func escapeMdfind(_ string: String) -> String

    /// Runs AppleScript and returns output.
    /// - Parameters:
    ///   - script: The AppleScript to execute.
    ///   - identifier: Optional identifier for temp file naming (for debugging).
    /// - Returns: The script output as a string.
    /// - Throws: AppleScriptError.executionFailed if script fails.
    func run(_ script: String, identifier: String) throws -> String
}
