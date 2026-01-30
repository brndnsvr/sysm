import ArgumentParser
import Foundation
import SysmCore

struct MailMove: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "move",
        abstract: "Move a message to a different mailbox"
    )

    @Argument(help: "Message ID")
    var id: String

    @Argument(help: "Target mailbox name")
    var mailbox: String

    @Option(name: .long, help: "Target account name")
    var account: String?

    func run() throws {
        let service = Services.mail()

        do {
            try service.moveMessage(id: id, toMailbox: mailbox, accountName: account)
            print("Message moved to '\(mailbox)'")
        } catch {
            fputs("Error: \(error.localizedDescription)\n", stderr)
            throw ExitCode.failure
        }
    }
}
