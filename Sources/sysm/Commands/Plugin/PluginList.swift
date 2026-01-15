import ArgumentParser
import Foundation

struct PluginList: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List installed plugins"
    )

    // MARK: - Options

    @Flag(name: .long, help: "Output as JSON")
    var json: Bool = false

    @Flag(name: .shortAndLong, help: "Show detailed information")
    var verbose: Bool = false

    // MARK: - Execution

    func run() throws {
        let manager = Services.plugins()
        let plugins = try manager.listPlugins()

        if plugins.isEmpty {
            if json {
                print("[]")
            } else {
                print("No plugins installed")
                print("\nCreate one with: sysm plugin create <name>")
            }
            return
        }

        if json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(plugins)
            print(String(data: data, encoding: .utf8)!)
        } else {
            print("Installed Plugins (\(plugins.count)):\n")
            for plugin in plugins {
                print("  \(plugin.name) v\(plugin.version)")
                if let desc = plugin.description {
                    print("    \(desc)")
                }
                print("    Commands: \(plugin.commands.map { $0.name }.joined(separator: ", "))")
                if verbose {
                    print("    Path: \(plugin.path)")
                    if let author = plugin.author, !author.isEmpty {
                        print("    Author: \(author)")
                    }
                }
                print("")
            }
        }
    }
}
