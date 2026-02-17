import ArgumentParser
import Foundation
import SysmCore

struct OutlookRead: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "read",
        abstract: "Read an Outlook message"
    )

    @Argument(help: "Message ID")
    var id: String

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.outlook()

        guard let message = try service.getMessage(id: id) else {
            print("Message '\(id)' not found")
            throw ExitCode.failure
        }

        if json {
            try OutputFormatter.printJSON(message)
        } else {
            print("Subject: \(message.subject)")
            print("From:    \(message.from)")
            print("To:      \(message.to)")
            if let cc = message.cc { print("Cc:      \(cc)") }
            print("Date:    \(message.dateReceived)")
            print("Read:    \(message.isRead ? "Yes" : "No")")
            print("\n\(message.body)")
        }
    }
}
