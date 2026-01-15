import ArgumentParser
import Foundation

struct PluginInfo: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "info",
        abstract: "Show detailed information about a plugin"
    )

    // MARK: - Arguments

    @Argument(help: "Name of the plugin")
    var name: String

    // MARK: - Options

    @Flag(name: .long, help: "Output as JSON")
    var json: Bool = false

    // MARK: - Execution

    func run() throws {
        let manager = Services.plugins()
        let plugin = try manager.getPlugin(name: name)

        if json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(plugin)
            print(String(data: data, encoding: .utf8)!)
        } else {
            print(manager.generateHelp(for: plugin))
        }
    }
}
