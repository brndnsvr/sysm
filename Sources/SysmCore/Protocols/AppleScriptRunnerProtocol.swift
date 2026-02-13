import Foundation

/// Protocol defining AppleScript execution operations with safety and escaping utilities.
///
/// This protocol handles running AppleScript code with proper string escaping to prevent
/// injection attacks and ensure safe execution. Provides utilities for both general AppleScript
/// string interpolation and specialized escaping for mdfind queries.
///
/// ## Security
///
/// AppleScript is vulnerable to injection attacks when user input is concatenated into scripts.
/// Always use ``escape(_:)`` for any user-provided strings before interpolating into AppleScript.
///
/// ## Usage Example
///
/// ```swift
/// let runner = AppleScriptRunner()
///
/// // Safe string interpolation
/// let userInput = "John's Project"
/// let safeName = runner.escape(userInput)
/// let script = """
/// tell application "Contacts"
///     set p to make new person with properties {name:"\(safeName)"}
/// end tell
/// """
/// let output = try runner.run(script, identifier: "create-contact")
///
/// // Mdfind query escaping
/// let query = "user's file.txt"
/// let safeQuery = runner.escapeMdfind(query)
/// ```
///
/// ## Thread Safety
///
/// Implementations are marked as `Sendable` and safe to use across actor boundaries.
/// AppleScript execution is synchronous.
///
/// ## Error Handling
///
/// Methods can throw ``AppleScriptError`` variants:
/// - ``AppleScriptError/executionFailed(_:exitCode:stderr:)`` - Script execution failed
/// - ``AppleScriptError/compileError(_:)`` - Script syntax error
/// - ``AppleScriptError/timeout`` - Script exceeded execution timeout
///
public protocol AppleScriptRunnerProtocol: Sendable {
    // MARK: - String Escaping

    /// Escapes a string for safe interpolation into AppleScript.
    ///
    /// Escapes special characters (quotes, backslashes, etc.) to prevent AppleScript injection
    /// and ensure the string is safely embedded in AppleScript code.
    ///
    /// - Parameter string: The string to escape.
    /// - Returns: The escaped string safe for AppleScript interpolation.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let input = "Say \"Hello\""
    /// let safe = runner.escape(input)  // "Say \\\"Hello\\\""
    /// let script = "display dialog \"\(safe)\""
    /// ```
    ///
    /// ## Important
    ///
    /// Always escape user input before embedding in AppleScript to prevent injection attacks.
    func escape(_ string: String) -> String

    /// Escapes a string for safe use in mdfind queries (single-quoted strings).
    ///
    /// Provides specialized escaping for Spotlight metadata queries used with mdfind.
    /// Different from general AppleScript escaping due to mdfind's single-quote syntax.
    ///
    /// - Parameter string: The string to escape for mdfind query.
    /// - Returns: The escaped string safe for mdfind queries.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let filename = "user's document.pdf"
    /// let safe = runner.escapeMdfind(filename)
    /// let query = "kMDItemDisplayName == '\(safe)'"
    /// ```
    func escapeMdfind(_ string: String) -> String

    // MARK: - Script Execution

    /// Runs AppleScript and returns output.
    ///
    /// Executes the provided AppleScript code using the `osascript` command-line tool.
    /// The script is written to a temporary file for execution and cleaned up automatically.
    ///
    /// - Parameters:
    ///   - script: The AppleScript source code to execute.
    ///   - identifier: Optional identifier for temp file naming, useful for debugging
    ///     (appears in temp file path as `/tmp/sysm-applescript-{identifier}-{random}.scpt`).
    /// - Returns: The script's output as a string (from stdout).
    /// - Throws: ``AppleScriptError/executionFailed(_:exitCode:stderr:)`` if script execution fails.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let script = """
    /// tell application "Finder"
    ///     return name of home
    /// end tell
    /// """
    /// let result = try runner.run(script, identifier: "get-home-name")
    /// print("Home folder: \(result)")
    /// ```
    ///
    /// ## Error Details
    ///
    /// The error includes:
    /// - `message`: User-friendly error description
    /// - `exitCode`: osascript exit code
    /// - `stderr`: Full error output for debugging
    func run(_ script: String, identifier: String) throws -> String
}
