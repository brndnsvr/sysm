import ArgumentParser
import Foundation
import SysmCore

struct MailDelete: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a message"
    )

    @Argument(help: "Message ID")
    var id: String

    @Flag(name: .shortAndLong, help: "Skip confirmation prompt")
    var force: Bool = false

    func run() throws {
        let service = Services.mail()

        if !force {
            let prompt: String
            if let message = try? service.getMessage(id: id) {
                prompt = "Delete message '\(message.subject)'? [y/N] "
            } else {
                prompt = "Delete message with ID '\(id)'? [y/N] "
            }
            guard CLI.confirm(prompt) else { return }
        }

        try service.deleteMessage(id: id)
        print("Message deleted")
    }
}
