import ArgumentParser
import Foundation
import SysmCore

struct SlackSend: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "send",
        abstract: "Send a Slack message"
    )

    @Argument(help: "Channel name (e.g. #general or general)")
    var channel: String

    @Argument(help: "Message text")
    var message: String

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let service = Services.slack()
        let result = try await service.sendMessage(channel: channel, text: message)

        if json {
            try OutputFormatter.printJSON(result)
        } else {
            print("Message sent to #\(result.channel)")
        }
    }
}
