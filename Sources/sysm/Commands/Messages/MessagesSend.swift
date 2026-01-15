import ArgumentParser
import Foundation

struct MessagesSend: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "send",
        abstract: "Send an iMessage"
    )

    @Argument(help: "Recipient phone number or email")
    var recipient: String

    @Argument(help: "Message to send")
    var message: String

    func run() throws {
        let service = Services.messages()
        try service.sendMessage(to: recipient, message: message)
        print("Message sent to \(recipient)")
    }
}
