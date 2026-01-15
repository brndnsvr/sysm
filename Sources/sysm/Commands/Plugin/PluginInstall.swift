import ArgumentParser
import Foundation

struct PluginInstall: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "install",
        abstract: "Install a plugin from a directory"
    )

    // MARK: - Arguments

    @Argument(help: "Path to plugin directory")
    var path: String

    // MARK: - Options

    @Flag(name: .long, help: "Overwrite existing plugin")
    var force: Bool = false

    @Flag(name: .long, help: "Output as JSON")
    var json: Bool = false

    // MARK: - Execution

    func run() throws {
        let manager = Services.plugins()
        let plugin = try manager.installPlugin(from: path, force: force)

        if json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(plugin)
            print(String(data: data, encoding: .utf8)!)
        } else {
            print("Installed plugin: \(plugin.name) v\(plugin.version)")
            if let desc = plugin.description {
                print("Description: \(desc)")
            }
            print("Commands: \(plugin.commands.map { $0.name }.joined(separator: ", "))")
            print("\nRun with: sysm plugin run \(plugin.name) <command>")
        }
    }
}
