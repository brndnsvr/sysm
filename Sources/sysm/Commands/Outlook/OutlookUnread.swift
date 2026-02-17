import ArgumentParser
import Foundation
import SysmCore

struct OutlookUnread: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "unread",
        abstract: "List unread Outlook messages"
    )

    @Option(name: .long, help: "Maximum messages (default: 20)")
    var limit: Int = 20

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.outlook()
        let messages = try service.getUnread(limit: limit)

        if json {
            try OutputFormatter.printJSON(messages)
        } else {
            OutlookFormatting.printMessages(messages, header: "Unread Messages", emptyMessage: "No unread messages")
        }
    }
}
