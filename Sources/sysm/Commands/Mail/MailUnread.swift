import ArgumentParser
import Foundation
import SysmCore

struct MailUnread: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "unread",
        abstract: "List unread messages"
    )

    @Option(name: .long, help: "Maximum messages to show (default: 50)")
    var limit: Int = 50

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.mail()
        let messages = try service.getUnreadMessages(limit: limit)

        if json {
            try OutputFormatter.printJSON(messages)
        } else {
            if messages.isEmpty {
                print("No unread messages")
            } else {
                print("Unread Messages (\(messages.count)):")
                for msg in messages {
                    print("\n  [\(msg.id)] \(msg.subject)")
                    print("  From: \(msg.from)")
                    print("  Date: \(msg.dateReceived)")
                }
            }
        }
    }
}
