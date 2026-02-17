import ArgumentParser
import Foundation
import SysmCore

struct SlackChannels: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "channels",
        abstract: "List Slack channels"
    )

    @Option(name: .long, help: "Maximum channels (default: 100)")
    var limit: Int = 100

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let service = Services.slack()
        let channels = try await service.listChannels(limit: limit)

        if json {
            try OutputFormatter.printJSON(channels)
        } else {
            if channels.isEmpty {
                print("No channels found")
            } else {
                print("Slack Channels (\(channels.count)):\n")
                for ch in channels {
                    let visibility = ch.isPrivate ? "private" : "public"
                    let members = ch.memberCount.map { " (\($0) members)" } ?? ""
                    print("  #\(ch.name) [\(visibility)]\(members)")
                    if let topic = ch.topic, !topic.isEmpty {
                        print("    \(topic)")
                    }
                }
            }
        }
    }
}
