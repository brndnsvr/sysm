import ArgumentParser
import Foundation
import SysmCore

struct ContactsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "contacts",
        abstract: "Search and view contacts",
        subcommands: [
            ContactsSearch.self,
            ContactsShow.self,
            ContactsEmail.self,
            ContactsPhone.self,
            ContactsBirthdays.self,
            ContactsGroups.self,
        ],
        defaultSubcommand: ContactsSearch.self
    )
}
