import ArgumentParser
import Foundation
import SysmCore

struct OutlookInbox: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "inbox",
        abstract: "List recent Outlook inbox messages"
    )

    @Option(name: .long, help: "Maximum messages (default: 20)")
    var limit: Int = 20

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.outlook()
        let messages = try service.getInbox(limit: limit)

        if json {
            try OutputFormatter.printJSON(messages)
        } else {
            OutlookFormatting.printMessages(messages, header: "Outlook Inbox", emptyMessage: "Inbox is empty")
        }
    }
}
