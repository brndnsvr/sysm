import ArgumentParser
import Foundation
import SysmCore

struct MailInbox: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "inbox",
        abstract: "List recent inbox messages"
    )

    @Option(name: .long, help: "Filter by account name")
    var account: String?

    @Option(name: .long, help: "Maximum messages to show (default: 20)")
    var limit: Int = 20

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.mail()
        let messages = try service.getInboxMessages(accountName: account, limit: limit)

        if json {
            try OutputFormatter.printJSON(messages)
        } else {
            MailFormatting.printMessageList(
                messages,
                header: "Inbox",
                emptyMessage: "Inbox is empty"
            )
        }
    }
}
