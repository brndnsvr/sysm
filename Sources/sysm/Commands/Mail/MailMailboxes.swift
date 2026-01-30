import ArgumentParser
import Foundation
import SysmCore

struct MailMailboxes: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "mailboxes",
        abstract: "List mailboxes"
    )

    @Option(name: .long, help: "Filter by account name")
    var account: String?

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.mail()
        let mailboxes = try service.getMailboxes(accountName: account)

        if json {
            try OutputFormatter.printJSON(mailboxes)
        } else {
            if mailboxes.isEmpty {
                print("No mailboxes found")
            } else {
                print("Mailboxes (\(mailboxes.count)):")
                var currentAccount = ""
                for mb in mailboxes {
                    if mb.accountName != currentAccount {
                        currentAccount = mb.accountName
                        print("\n  \(currentAccount):")
                    }
                    let unreadIndicator = mb.unreadCount > 0 ? " (\(mb.unreadCount) unread)" : ""
                    print("    \(mb.name) - \(mb.messageCount) messages\(unreadIndicator)")
                }
            }
        }
    }
}
