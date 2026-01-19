import ArgumentParser
import Foundation
import SysmCore

struct MessagesRecent: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "recent",
        abstract: "List recent conversations"
    )

    @Option(name: .long, help: "Maximum conversations to show (default: 20)")
    var limit: Int = 20

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.messages()
        let conversations = try service.getRecentConversations(limit: limit)

        if json {
            try OutputFormatter.printJSON(conversations)
        } else {
            if conversations.isEmpty {
                print("No recent conversations")
            } else {
                print("Recent Conversations (\(conversations.count)):")
                for conv in conversations {
                    print("\n  \(conv.name)")
                    print("  ID: \(conv.id)")
                    print("  Participants: \(conv.participants)")
                }
            }
        }
    }
}
