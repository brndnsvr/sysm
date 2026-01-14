import ArgumentParser
import Foundation

struct PluginRemove: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "remove",
        abstract: "Remove an installed plugin"
    )

    // MARK: - Arguments

    @Argument(help: "Name of the plugin to remove")
    var name: String

    // MARK: - Execution

    func run() throws {
        let manager = PluginManager()

        // Verify plugin exists
        _ = try manager.getPlugin(name: name)

        try manager.removePlugin(name: name)
        print("Removed plugin: \(name)")
    }
}
