import Foundation

/// Protocol defining Shortcuts service operations using the macOS shortcuts CLI.
///
/// Implementations provide access to the user's Shortcuts app automations,
/// supporting listing available shortcuts and executing them with optional input.
protocol ShortcutsServiceProtocol {
    /// Lists all available shortcuts.
    /// - Returns: Array of shortcut names.
    func list() throws -> [String]

    /// Runs a shortcut by name.
    /// - Parameters:
    ///   - name: Name of the shortcut to run.
    ///   - input: Optional input to pass to the shortcut via stdin.
    /// - Returns: The shortcut's output.
    func run(name: String, input: String?) throws -> String
}
