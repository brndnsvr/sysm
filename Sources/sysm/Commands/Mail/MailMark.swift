import ArgumentParser
import Foundation
import SysmCore

struct MailMark: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "mark",
        abstract: "Mark a message as read or unread"
    )

    @Argument(help: "Message ID")
    var id: String

    @Flag(name: .long, help: "Mark as read")
    var read = false

    @Flag(name: .long, help: "Mark as unread")
    var unread = false

    func validate() throws {
        if read == unread {
            throw ValidationError("Specify either --read or --unread")
        }
    }

    func run() throws {
        let service = Services.mail()

        try service.markMessage(id: id, read: read)
        print("Message marked as \(read ? "read" : "unread")")
    }
}
