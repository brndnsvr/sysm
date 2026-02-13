import Foundation

/// Protocol defining Shortcuts service operations using the macOS shortcuts CLI.
///
/// This protocol provides access to the user's Shortcuts app automations through the `shortcuts`
/// command-line tool, supporting listing available shortcuts and executing them with optional input.
///
/// ## Permission Requirements
///
/// Shortcuts execution may require:
/// - Automation permissions for the Shortcuts app
/// - Individual shortcut permissions (varies by shortcut actions)
/// - Shortcuts app must be installed (macOS 12+)
///
/// ## Usage Example
///
/// ```swift
/// let service = ShortcutsService()
///
/// // List all shortcuts
/// let shortcuts = try service.list()
/// print("Available shortcuts: \(shortcuts.joined(separator: ", "))")
///
/// // Run a shortcut without input
/// let output = try service.run(name: "Morning Routine", input: nil)
/// print("Result: \(output)")
///
/// // Run a shortcut with input
/// let result = try service.run(
///     name: "Process Text",
///     input: "Hello, world!"
/// )
/// print(result)
/// ```
///
/// ## Thread Safety
///
/// Implementations are marked as `Sendable` and safe to use across actor boundaries.
/// Shortcut execution is synchronous and blocking.
///
/// ## Error Handling
///
/// Methods can throw ``ShortcutsError`` variants:
/// - ``ShortcutsError/shortcutNotFound(_:)`` - Shortcut doesn't exist
/// - ``ShortcutsError/executionFailed(_:exitCode:stderr:)`` - Shortcut execution failed
/// - ``ShortcutsError/cliNotAvailable`` - shortcuts CLI tool not found
/// - ``ShortcutsError/timeout`` - Shortcut exceeded execution timeout
///
public protocol ShortcutsServiceProtocol: Sendable {
    // MARK: - Listing

    /// Lists all available shortcuts.
    ///
    /// Returns names of all shortcuts configured in the Shortcuts app.
    ///
    /// - Returns: Array of shortcut names.
    /// - Throws:
    ///   - ``ShortcutsError/cliNotAvailable`` if shortcuts CLI not found.
    ///   - ``ShortcutsError/executionFailed(_:exitCode:stderr:)`` if listing failed.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let shortcuts = try service.list()
    /// for name in shortcuts.sorted() {
    ///     print("- \(name)")
    /// }
    /// ```
    func list() throws -> [String]

    // MARK: - Execution

    /// Runs a shortcut by name with optional input.
    ///
    /// Executes the named shortcut, optionally passing input text via stdin. The shortcut's
    /// output is returned as a string.
    ///
    /// - Parameters:
    ///   - name: Name of the shortcut to run (case-sensitive).
    ///   - input: Optional input text to pass to the shortcut via stdin.
    /// - Returns: The shortcut's output as a string.
    /// - Throws:
    ///   - ``ShortcutsError/shortcutNotFound(_:)`` if shortcut doesn't exist.
    ///   - ``ShortcutsError/executionFailed(_:exitCode:stderr:)`` if execution failed.
    ///   - ``ShortcutsError/timeout`` if shortcut takes too long.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Run without input
    /// let greeting = try service.run(name: "Get Greeting", input: nil)
    ///
    /// // Run with input
    /// let processed = try service.run(
    ///     name: "Convert to Uppercase",
    ///     input: "hello world"
    /// )
    /// print(processed) // "HELLO WORLD"
    /// ```
    ///
    /// ## Notes
    ///
    /// - Shortcut names are case-sensitive
    /// - Input is passed via stdin (not all shortcuts accept input)
    /// - Output comes from the shortcut's result action
    /// - Long-running shortcuts may time out
    func run(name: String, input: String?) throws -> String
}
