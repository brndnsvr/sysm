import ArgumentParser
import Foundation

struct MessagesRead: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "read",
        abstract: "Read messages from a conversation"
    )

    @Argument(help: "Conversation ID")
    var conversationId: String

    @Option(name: .long, help: "Maximum messages to show (default: 30)")
    var limit: Int = 30

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = MessagesService()
        let messages = try service.getMessages(conversationId: conversationId, limit: limit)

        if json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(messages)
            if let jsonString = String(data: data, encoding: .utf8) {
                print(jsonString)
            }
        } else {
            if messages.isEmpty {
                print("No messages in conversation")
            } else {
                print("Messages (\(messages.count)):")
                for msg in messages {
                    print("\n  [\(msg.date)]")
                    print("  From: \(msg.sender)")
                    print("  \(msg.content)")
                }
            }
        }
    }
}
