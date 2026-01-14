import ArgumentParser
import Foundation

struct MailInbox: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "inbox",
        abstract: "List recent inbox messages"
    )

    @Option(name: .long, help: "Maximum messages to show (default: 20)")
    var limit: Int = 20

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = MailService()
        let messages = try service.getInboxMessages(limit: limit)

        if json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(messages)
            if let jsonString = String(data: data, encoding: .utf8) {
                print(jsonString)
            }
        } else {
            if messages.isEmpty {
                print("Inbox is empty")
            } else {
                print("Inbox (\(messages.count) messages):")
                for msg in messages {
                    let readStatus = msg.isRead ? " " : "*"
                    print("\n  \(readStatus)[\(msg.id)] \(msg.subject)")
                    print("   From: \(msg.from)")
                    print("   Date: \(msg.dateReceived)")
                }
                print("\n  (* = unread)")
            }
        }
    }
}
