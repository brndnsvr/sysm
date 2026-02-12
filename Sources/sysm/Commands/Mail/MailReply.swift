import ArgumentParser
import Foundation
import SysmCore

struct MailReply: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "reply",
        abstract: "Reply to a message"
    )

    @Argument(help: "Message ID to reply to")
    var messageId: String

    @Option(name: .long, help: "Reply body text")
    var body: String

    @Flag(name: .long, help: "Reply to all recipients (reply all)")
    var all: Bool = false

    @Flag(name: .long, help: "Send immediately instead of creating draft")
    var send: Bool = false

    func run() throws {
        let service = Services.mail()

        let replyId = try service.reply(
            messageId: messageId,
            body: body,
            replyAll: all,
            send: send
        )

        if send {
            print("Reply sent (ID: \(replyId))")
        } else {
            print("Reply draft created (ID: \(replyId))")
            print("Open Mail.app to review and send")
        }
    }
}
