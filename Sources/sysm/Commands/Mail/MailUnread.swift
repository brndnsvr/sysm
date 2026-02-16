import ArgumentParser
import Foundation
import SysmCore

struct MailUnread: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "unread",
        abstract: "List unread messages"
    )

    @Option(name: .long, help: "Filter by account name")
    var account: String?

    @Option(name: .long, help: "Maximum messages to show (default: 50)")
    var limit: Int = 50

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.mail()
        let messages = try service.getUnreadMessages(accountName: account, limit: limit)

        if json {
            try OutputFormatter.printJSON(messages)
        } else {
            MailFormatting.printMessageList(
                messages,
                header: "Unread Messages",
                emptyMessage: "No unread messages",
                showReadStatus: false
            )
        }
    }
}
