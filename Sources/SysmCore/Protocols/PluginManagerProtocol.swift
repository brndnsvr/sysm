import Foundation

/// Protocol defining plugin manager operations for sysm's plugin system.
///
/// Implementations provide plugin discovery, installation, removal, and execution
/// for extending sysm with custom shell script-based commands.
public protocol PluginManagerProtocol: Sendable {
    /// Lists all installed plugins.
    /// - Returns: Array of plugins.
    func listPlugins() throws -> [PluginManager.Plugin]

    /// Retrieves a specific plugin by name.
    /// - Parameter name: The plugin name.
    /// - Returns: The plugin.
    func getPlugin(name: String) throws -> PluginManager.Plugin

    /// Creates a new plugin scaffold.
    /// - Parameters:
    ///   - name: Plugin name.
    ///   - description: Optional plugin description.
    ///   - force: If true, overwrites existing plugin.
    /// - Returns: Path to the created plugin.
    func createPlugin(name: String, description: String?, force: Bool) throws -> String

    /// Installs a plugin from a local path.
    /// - Parameters:
    ///   - source: Path to the plugin directory.
    ///   - force: If true, overwrites existing plugin.
    /// - Returns: The installed plugin.
    func installPlugin(from source: String, force: Bool) throws -> PluginManager.Plugin

    /// Removes a plugin.
    /// - Parameter name: Name of the plugin to remove.
    func removePlugin(name: String) throws

    /// Runs a command from a plugin.
    /// - Parameters:
    ///   - plugin: Plugin name.
    ///   - command: Command name within the plugin.
    ///   - args: Arguments to pass to the command.
    ///   - timeout: Maximum execution time.
    /// - Returns: Execution result.
    func runCommand(plugin: String, command: String, args: [String: String], timeout: TimeInterval) throws -> PluginManager.ExecutionResult

    /// Generates help text for a plugin.
    /// - Parameter plugin: The plugin.
    /// - Returns: Formatted help text.
    func generateHelp(for plugin: PluginManager.Plugin) -> String
}
