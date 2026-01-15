import ArgumentParser
import Foundation

struct MailSearch: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "search",
        abstract: "Search messages by subject or sender"
    )

    @Argument(help: "Search query")
    var query: String

    @Option(name: .long, help: "Maximum results (default: 30)")
    var limit: Int = 30

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.mail()
        let messages = try service.searchMessages(query: query, limit: limit)

        if json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(messages)
            if let jsonString = String(data: data, encoding: .utf8) {
                print(jsonString)
            }
        } else {
            if messages.isEmpty {
                print("No messages found for '\(query)'")
            } else {
                print("Search Results (\(messages.count)):")
                for msg in messages {
                    let readStatus = msg.isRead ? " " : "*"
                    print("\n  \(readStatus)[\(msg.id)] \(msg.subject)")
                    print("   From: \(msg.from)")
                    print("   Date: \(msg.dateReceived)")
                }
            }
        }
    }
}
