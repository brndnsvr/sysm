import ArgumentParser
import Foundation

struct ShortcutsCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "shortcuts",
        abstract: "Manage Apple Shortcuts",
        subcommands: [
            ShortcutsList.self,
            ShortcutsRun.self,
        ],
        defaultSubcommand: ShortcutsList.self
    )
}
