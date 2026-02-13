import Foundation

/// Protocol defining plugin manager operations for sysm's extensibility system.
///
/// This protocol provides plugin discovery, installation, removal, and execution for extending
/// sysm with custom shell script-based commands. Plugins are organized in `~/.sysm/plugins/`
/// with a manifest file defining their commands and metadata.
///
/// ## Plugin Structure
///
/// Each plugin is a directory containing:
/// - `plugin.yml` - Manifest with metadata and command definitions
/// - Command scripts (shell, Python, etc.)
/// - Optional README and documentation
///
/// ## Usage Example
///
/// ```swift
/// let manager = PluginManager()
///
/// // List installed plugins
/// let plugins = try manager.listPlugins()
/// for plugin in plugins {
///     print("\(plugin.name): \(plugin.description ?? "")")
///     for command in plugin.commands {
///         print("  - \(command.name): \(command.description ?? "")")
///     }
/// }
///
/// // Create a new plugin
/// let path = try manager.createPlugin(
///     name: "git-tools",
///     description: "Git workflow helpers",
///     force: false
/// )
/// print("Created plugin at: \(path)")
///
/// // Run a plugin command
/// let result = try manager.runCommand(
///     plugin: "git-tools",
///     command: "squash",
///     args: ["feature-branch": "main"],
///     timeout: 30.0
/// )
/// print(result.stdout)
/// ```
///
/// ## Thread Safety
///
/// Implementations are marked as `Sendable` and safe to use across actor boundaries.
/// Plugin operations are synchronous.
///
/// ## Error Handling
///
/// Methods can throw ``PluginError`` variants:
/// - ``PluginError/pluginNotFound(_:)`` - Plugin doesn't exist
/// - ``PluginError/commandNotFound(_:plugin:)`` - Command not found in plugin
/// - ``PluginError/invalidManifest(_:)`` - plugin.yml is malformed
/// - ``PluginError/pluginAlreadyExists(_:)`` - Plugin with name already exists
/// - ``PluginError/executionFailed(_:exitCode:stderr:)`` - Command execution failed
/// - ``PluginError/timeout`` - Command execution exceeded timeout
///
public protocol PluginManagerProtocol: Sendable {
    // MARK: - Plugin Discovery

    /// Lists all installed plugins.
    ///
    /// Scans the plugins directory (`~/.sysm/plugins/`) and returns metadata for all valid plugins.
    ///
    /// - Returns: Array of ``PluginManager/Plugin`` objects.
    /// - Throws:
    ///   - ``PluginError/invalidManifest(_:)`` if a plugin manifest is malformed.
    ///   - File system errors if plugins directory doesn't exist.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let plugins = try manager.listPlugins()
    /// print("Installed plugins: \(plugins.count)")
    /// for plugin in plugins {
    ///     print("  \(plugin.name) v\(plugin.version)")
    ///     print("    Commands: \(plugin.commands.map { $0.name }.joined(separator: ", "))")
    /// }
    /// ```
    func listPlugins() throws -> [PluginManager.Plugin]

    /// Retrieves a specific plugin by name.
    ///
    /// Loads and returns full metadata for the named plugin.
    ///
    /// - Parameter name: The plugin name (directory name).
    /// - Returns: The ``PluginManager/Plugin`` object.
    /// - Throws:
    ///   - ``PluginError/pluginNotFound(_:)`` if plugin doesn't exist.
    ///   - ``PluginError/invalidManifest(_:)`` if plugin manifest is malformed.
    func getPlugin(name: String) throws -> PluginManager.Plugin

    // MARK: - Plugin Management

    /// Creates a new plugin scaffold.
    ///
    /// Generates a new plugin directory with template manifest and example command script.
    ///
    /// - Parameters:
    ///   - name: Plugin name (will become directory name, must be filesystem-safe).
    ///   - description: Optional plugin description for manifest.
    ///   - force: If true, overwrites existing plugin with same name.
    /// - Returns: Absolute path to the created plugin directory.
    /// - Throws:
    ///   - ``PluginError/pluginAlreadyExists(_:)`` if plugin exists and force is false.
    ///   - File system errors if cannot create directory or files.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let path = try manager.createPlugin(
    ///     name: "backup-tools",
    ///     description: "Automated backup utilities",
    ///     force: false
    /// )
    /// print("Plugin created at: \(path)")
    /// print("Edit \(path)/plugin.yml to configure")
    /// ```
    ///
    /// ## Generated Structure
    ///
    /// Creates:
    /// - `plugin.yml` - Manifest template
    /// - `example-command.sh` - Sample command script
    /// - `README.md` - Plugin documentation template
    func createPlugin(name: String, description: String?, force: Bool) throws -> String

    /// Installs a plugin from a local path.
    ///
    /// Copies a plugin directory into the plugins directory, validating the manifest first.
    ///
    /// - Parameters:
    ///   - source: Path to the plugin directory to install.
    ///   - force: If true, overwrites existing plugin with same name.
    /// - Returns: The installed ``PluginManager/Plugin`` object.
    /// - Throws:
    ///   - ``PluginError/invalidManifest(_:)`` if plugin manifest is malformed.
    ///   - ``PluginError/pluginAlreadyExists(_:)`` if plugin exists and force is false.
    ///   - File system errors if cannot copy files.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let plugin = try manager.installPlugin(
    ///     from: "~/Downloads/my-plugin",
    ///     force: false
    /// )
    /// print("Installed: \(plugin.name)")
    /// ```
    func installPlugin(from source: String, force: Bool) throws -> PluginManager.Plugin

    /// Removes a plugin.
    ///
    /// Deletes the plugin directory and all its contents.
    ///
    /// - Parameter name: Name of the plugin to remove.
    /// - Throws:
    ///   - ``PluginError/pluginNotFound(_:)`` if plugin doesn't exist.
    ///   - File system errors if cannot delete files.
    func removePlugin(name: String) throws

    // MARK: - Command Execution

    /// Runs a command from a plugin.
    ///
    /// Executes a plugin command script with specified arguments. Arguments are passed as
    /// environment variables (prefixed with `ARG_`) for easy access in scripts.
    ///
    /// - Parameters:
    ///   - plugin: Plugin name.
    ///   - command: Command name within the plugin.
    ///   - args: Dictionary of argument names to values (passed as environment variables).
    ///   - timeout: Maximum execution time in seconds.
    /// - Returns: ``PluginManager/ExecutionResult`` with exit code, stdout, stderr, and duration.
    /// - Throws:
    ///   - ``PluginError/pluginNotFound(_:)`` if plugin doesn't exist.
    ///   - ``PluginError/commandNotFound(_:plugin:)`` if command doesn't exist in plugin.
    ///   - ``PluginError/executionFailed(_:exitCode:stderr:)`` if command execution failed.
    ///   - ``PluginError/timeout`` if command exceeds timeout.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let result = try manager.runCommand(
    ///     plugin: "backup-tools",
    ///     command: "backup",
    ///     args: [
    ///         "source": "/data",
    ///         "dest": "/backups",
    ///         "compress": "true"
    ///     ],
    ///     timeout: 300.0
    /// )
    ///
    /// if result.exitCode == 0 {
    ///     print("Backup completed:")
    ///     print(result.stdout)
    /// } else {
    ///     print("Backup failed:")
    ///     print(result.stderr)
    /// }
    /// print("Duration: \(result.duration)s")
    /// ```
    ///
    /// ## Argument Passing
    ///
    /// Arguments are available in scripts as environment variables:
    /// ```bash
    /// # args: ["source": "/data", "compress": "true"]
    /// # Becomes:
    /// # $ARG_source = "/data"
    /// # $ARG_compress = "true"
    /// ```
    func runCommand(plugin: String, command: String, args: [String: String], timeout: TimeInterval) throws -> PluginManager.ExecutionResult

    // MARK: - Help & Documentation

    /// Generates help text for a plugin.
    ///
    /// Creates formatted help output with plugin description, version, and command list.
    ///
    /// - Parameter plugin: The plugin object to generate help for.
    /// - Returns: Formatted help text string.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let plugin = try manager.getPlugin(name: "git-tools")
    /// let help = manager.generateHelp(for: plugin)
    /// print(help)
    /// ```
    ///
    /// ## Output Format
    ///
    /// ```
    /// git-tools v1.0.0
    /// Git workflow helpers
    ///
    /// Commands:
    ///   squash    Squash commits into one
    ///   cleanup   Remove merged branches
    ///   sync      Sync with upstream
    /// ```
    func generateHelp(for plugin: PluginManager.Plugin) -> String
}
