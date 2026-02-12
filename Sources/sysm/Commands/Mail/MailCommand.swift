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
            MailMark.self,
            MailDelete.self,
            MailMailboxes.self,
            MailMove.self,
            MailFlag.self,
            MailSend.self,
            MailAttachments.self,
            MailReply.self,
            MailForward.self,
        ]
    )
}
