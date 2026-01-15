import ArgumentParser
import Foundation

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
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let jsonShortcuts = shortcuts.map { ["name": $0] }
            let data = try encoder.encode(jsonShortcuts)
            print(String(data: data, encoding: .utf8)!)
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
