import Foundation

/// Protocol defining script execution operations for multiple scripting languages.
///
/// This protocol handles running scripts in various languages including bash, zsh, Python,
/// AppleScript, and Swift. Supports both file-based and inline code execution with timeout
/// control, custom environments, and comprehensive error reporting.
///
/// ## Supported Languages
///
/// - Shell scripts: bash, zsh (auto-detected from shebang or extension)
/// - Python scripts (.py)
/// - AppleScript (.scpt, .applescript)
/// - Swift scripts (.swift)
///
/// ## Usage Example
///
/// ```swift
/// let runner = ScriptRunner()
///
/// // Run a script file
/// let result = try runner.runFile(
///     path: "/path/to/script.sh",
///     args: ["arg1", "arg2"],
///     scriptType: nil,  // Auto-detect from extension/shebang
///     timeout: 30.0,
///     env: ["MY_VAR": "value"]
/// )
/// print("Exit code: \(result.exitCode)")
/// print("Output: \(result.stdout)")
///
/// // Run inline code
/// let pythonCode = """
/// import sys
/// print(f"Hello from Python {sys.version}")
/// """
/// let result2 = try runner.runCode(
///     code: pythonCode,
///     scriptType: .python,
///     args: [],
///     timeout: 10.0,
///     env: [:]
/// )
/// ```
///
/// ## Thread Safety
///
/// Implementations are marked as `Sendable` and safe to use across actor boundaries.
/// Script execution is synchronous and blocking.
///
/// ## Error Handling
///
/// Methods can throw ``ScriptRunnerError`` variants:
/// - ``ScriptRunnerError/fileNotFound(_:)`` - Script file doesn't exist
/// - ``ScriptRunnerError/timeout(_:)`` - Script exceeded execution timeout
/// - ``ScriptRunnerError/executionFailed(_:exitCode:stderr:)`` - Script failed
/// - ``ScriptRunnerError/unsupportedType(_:)`` - Script type not supported
/// - ``ScriptRunnerError/interpreterNotFound(_:)`` - Required interpreter not installed
///
public protocol ScriptRunnerProtocol: Sendable {
    // MARK: - File Execution

    /// Runs a script from a file.
    ///
    /// Executes a script file with specified arguments, optional type override, timeout,
    /// and custom environment variables. Script type is auto-detected from file extension
    /// and shebang if not explicitly specified.
    ///
    /// - Parameters:
    ///   - path: Absolute or relative path to the script file.
    ///   - args: Arguments to pass to the script (available as $1, $2, etc. in shell or sys.argv in Python).
    ///   - scriptType: Optional explicit script type. If nil, auto-detected from extension and shebang.
    ///   - timeout: Maximum execution time in seconds. Script is terminated if exceeded.
    ///   - env: Additional environment variables to set for script execution (merged with system env).
    /// - Returns: ``ScriptRunner/ExecutionResult`` containing exit code, stdout, stderr, and duration.
    /// - Throws:
    ///   - ``ScriptRunnerError/fileNotFound(_:)`` if script file doesn't exist.
    ///   - ``ScriptRunnerError/timeout(_:)`` if script exceeds timeout.
    ///   - ``ScriptRunnerError/interpreterNotFound(_:)`` if required interpreter not found.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let result = try runner.runFile(
    ///     path: "~/scripts/backup.sh",
    ///     args: ["/data", "/backup"],
    ///     scriptType: nil,
    ///     timeout: 300.0,
    ///     env: ["BACKUP_LOG": "/var/log/backup.log"]
    /// )
    /// if result.exitCode == 0 {
    ///     print("Backup completed in \(result.duration)s")
    /// } else {
    ///     print("Error: \(result.stderr)")
    /// }
    /// ```
    func runFile(
        path: String,
        args: [String],
        scriptType: ScriptRunner.ScriptType?,
        timeout: TimeInterval,
        env: [String: String]
    ) throws -> ScriptRunner.ExecutionResult

    // MARK: - Inline Code Execution

    /// Runs inline code in a specified language.
    ///
    /// Executes code directly without requiring a file. The code is written to a temporary
    /// file, executed, and cleaned up automatically.
    ///
    /// - Parameters:
    ///   - code: The source code to execute.
    ///   - scriptType: Script type/language (required for inline code).
    ///   - args: Arguments to pass to the script.
    ///   - timeout: Maximum execution time in seconds.
    ///   - env: Additional environment variables.
    /// - Returns: ``ScriptRunner/ExecutionResult`` containing exit code, stdout, stderr, and duration.
    /// - Throws:
    ///   - ``ScriptRunnerError/timeout(_:)`` if script exceeds timeout.
    ///   - ``ScriptRunnerError/interpreterNotFound(_:)`` if required interpreter not found.
    ///   - ``ScriptRunnerError/executionFailed(_:exitCode:stderr:)`` if script fails.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let bashCode = """
    /// #!/bin/bash
    /// echo "Processing $1"
    /// date
    /// """
    /// let result = try runner.runCode(
    ///     code: bashCode,
    ///     scriptType: .bash,
    ///     args: ["file.txt"],
    ///     timeout: 5.0,
    ///     env: [:]
    /// )
    /// print(result.stdout)
    /// ```
    func runCode(
        code: String,
        scriptType: ScriptRunner.ScriptType,
        args: [String],
        timeout: TimeInterval,
        env: [String: String]
    ) throws -> ScriptRunner.ExecutionResult
}
