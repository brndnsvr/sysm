import Foundation

/// Protocol for plugin manager operations
protocol PluginManagerProtocol {
    func listPlugins() throws -> [PluginManager.Plugin]
    func getPlugin(name: String) throws -> PluginManager.Plugin
    func createPlugin(name: String, description: String?, force: Bool) throws -> String
    func installPlugin(from source: String, force: Bool) throws -> PluginManager.Plugin
    func removePlugin(name: String) throws
    func runCommand(plugin: String, command: String, args: [String: String], timeout: TimeInterval) throws -> PluginManager.ExecutionResult
    func generateHelp(for plugin: PluginManager.Plugin) -> String
}
