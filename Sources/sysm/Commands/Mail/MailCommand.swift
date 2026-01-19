import ArgumentParser
import Foundation
import SysmCore

struct MailCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "mail",
        abstract: "Access Apple Mail messages",
        subcommands: [
            MailUnread.self,
            MailInbox.self,
            MailRead.self,
            MailSearch.self,
            MailAccounts.self,
            MailDraft.self,
        ],
        defaultSubcommand: MailUnread.self
    )
}
