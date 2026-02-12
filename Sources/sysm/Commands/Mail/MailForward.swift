import ArgumentParser
import Foundation
import SysmCore

struct MailForward: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "forward",
        abstract: "Forward a message"
    )

    @Argument(help: "Message ID to forward")
    var messageId: String

    @Option(name: .long, help: "Recipient email address")
    var to: String

    @Option(name: .long, help: "Forward body text")
    var body: String = ""

    @Flag(name: .long, help: "Send immediately instead of creating draft")
    var send: Bool = false

    func run() throws {
        let service = Services.mail()

        let forwardId = try service.forward(
            messageId: messageId,
            to: to,
            body: body,
            send: send
        )

        if send {
            print("Message forwarded (ID: \(forwardId))")
        } else {
            print("Forward draft created (ID: \(forwardId))")
            print("Open Mail.app to review and send")
        }
    }
}
