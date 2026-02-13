import ArgumentParser
import Foundation
import SysmCore

struct ContactsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "contacts",
        abstract: "Search, view, and manage contacts",
        subcommands: [
            ContactsSearch.self,
            ContactsShow.self,
            ContactsAdd.self,
            ContactsEdit.self,
            ContactsDelete.self,
            ContactsEmail.self,
            ContactsPhone.self,
            ContactsBirthdays.self,
            ContactsGroups.self,
            ContactsPhoto.self,
            ContactsDuplicates.self,
            ContactsMerge.self,
        ]
    )
}
