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
            // Try to get message subject for confirmation
            if let message = try? service.getMessage(id: id) {
                print("Delete message '\(message.subject)'? [y/N]: ", terminator: "")
            } else {
                print("Delete message with ID '\(id)'? [y/N]: ", terminator: "")
            }

            guard let response = readLine(), response.lowercased() == "y" else {
                print("Cancelled")
                return
            }
        }

        try service.deleteMessage(id: id)
        print("Message deleted")
    }
}
