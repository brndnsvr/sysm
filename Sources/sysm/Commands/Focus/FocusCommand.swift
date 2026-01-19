import ArgumentParser
import Foundation
import SysmCore

struct FocusCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "focus",
        abstract: "Manage Focus modes and Do Not Disturb",
        subcommands: [
            FocusStatus.self,
            FocusDND.self,
            FocusList.self,
        ],
        defaultSubcommand: FocusStatus.self
    )
}
