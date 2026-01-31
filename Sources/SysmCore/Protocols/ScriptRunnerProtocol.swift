import Foundation

/// Protocol defining script execution operations.
///
/// Implementations handle running scripts in various languages including
/// bash, zsh, Python, AppleScript, and Swift.
public protocol ScriptRunnerProtocol: Sendable {
    /// Run a script file.
    /// - Parameters:
    ///   - path: Path to the script file.
    ///   - args: Arguments to pass to the script.
    ///   - scriptType: Script type (auto-detected from extension/shebang if nil).
    ///   - timeout: Maximum execution time in seconds.
    ///   - env: Additional environment variables.
    /// - Returns: Execution result with exit code, stdout, stderr, and duration.
    func runFile(
        path: String,
        args: [String],
        scriptType: ScriptRunner.ScriptType?,
        timeout: TimeInterval,
        env: [String: String]
    ) throws -> ScriptRunner.ExecutionResult

    /// Run inline code.
    /// - Parameters:
    ///   - code: The code to execute.
    ///   - scriptType: Script type (required for inline code).
    ///   - args: Arguments to pass to the script.
    ///   - timeout: Maximum execution time in seconds.
    ///   - env: Additional environment variables.
    /// - Returns: Execution result with exit code, stdout, stderr, and duration.
    func runCode(
        code: String,
        scriptType: ScriptRunner.ScriptType,
        args: [String],
        timeout: TimeInterval,
        env: [String: String]
    ) throws -> ScriptRunner.ExecutionResult
}
