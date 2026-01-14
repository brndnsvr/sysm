import ArgumentParser
import Foundation

struct PluginCreate: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create a new plugin from template"
    )

    // MARK: - Arguments

    @Argument(help: "Name for the new plugin")
    var name: String

    // MARK: - Options

    @Option(name: .shortAndLong, help: "Description for the plugin")
    var description: String?

    @Flag(name: .long, help: "Overwrite existing plugin")
    var force: Bool = false

    // MARK: - Execution

    func run() throws {
        let manager = PluginManager()
        let path = try manager.createPlugin(name: name, description: description, force: force)

        print("Created plugin: \(name)")
        print("Location: \(path)")
        print("\nFiles created:")
        print("  plugin.yaml - Plugin manifest")
        print("  main.sh     - Main script")
        print("\nTest with:")
        print("  sysm plugin run \(name) hello")
        print("  sysm plugin run \(name) hello --name \"Your Name\"")
        print("\nEdit the manifest and scripts to add your commands.")
    }
}
