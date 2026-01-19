import ArgumentParser
import Foundation
import SysmCore

struct MailRead: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "read",
        abstract: "Read a specific message"
    )

    @Argument(help: "Message ID")
    var id: String

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.mail()

        guard let message = try service.getMessage(id: id) else {
            fputs("Message not found: \(id)\n", stderr)
            throw ExitCode.failure
        }

        if json {
            try OutputFormatter.printJSON(message)
        } else {
            print("Subject: \(message.subject)")
            print("From: \(message.from)")
            print("To: \(message.to)")
            print("Date: \(message.dateReceived)")
            print(String(repeating: "-", count: 60))
            print(message.content)
        }
    }
}
