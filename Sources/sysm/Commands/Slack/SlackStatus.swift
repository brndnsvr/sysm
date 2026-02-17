import ArgumentParser
import Foundation
import SysmCore

struct SlackStatus: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "status",
        abstract: "Set your Slack status"
    )

    @Argument(help: "Status text (use empty string to clear)")
    var text: String

    @Option(name: .long, help: "Status emoji (e.g. :coffee:)")
    var emoji: String?

    func run() async throws {
        let service = Services.slack()
        try await service.setStatus(text: text, emoji: emoji)

        if text.isEmpty {
            print("Status cleared")
        } else {
            let emojiStr = emoji.map { " \($0)" } ?? ""
            print("Status set: \(text)\(emojiStr)")
        }
    }
}
