import ArgumentParser
import Foundation
import SysmCore

struct ShortcutsList: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List available shortcuts"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.shortcuts()
        let shortcuts = try service.list()

        if json {
            let jsonShortcuts = shortcuts.map { ["name": $0] }
            try OutputFormatter.printJSON(jsonShortcuts)
        } else {
            if shortcuts.isEmpty {
                print("No shortcuts found")
            } else {
                print("Shortcuts (\(shortcuts.count)):")
                for shortcut in shortcuts {
                    print("  - \(shortcut)")
                }
            }
        }
    }
}
