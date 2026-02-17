import ArgumentParser
import SysmCore

struct ClipboardCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "clipboard",
        abstract: "Manage system clipboard",
        subcommands: [
            ClipboardPaste.self,
            ClipboardCopy.self,
            ClipboardClear.self,
        ]
    )
}
