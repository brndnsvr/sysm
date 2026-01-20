import ArgumentParser
import Foundation
import SysmCore

struct MessagesCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "messages",
        abstract: "Access Apple Messages (iMessage/SMS)",
        discussion: "Note: Messages access via AppleScript is limited on recent macOS versions.",
        subcommands: [
            MessagesSend.self,
            MessagesRecent.self,
            MessagesRead.self,
        ]
    )
}
