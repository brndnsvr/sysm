import ArgumentParser
import Foundation
import SysmCore

struct ContactsGroups: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "groups",
        abstract: "Manage contact groups",
        subcommands: [
            ContactsGroupsList.self,
            ContactsGroupsMembers.self,
            ContactsGroupsAddMember.self,
            ContactsGroupsRemoveMember.self,
            ContactsGroupsRename.self,
        ],
        defaultSubcommand: ContactsGroupsList.self
    )
}

struct ContactsGroupsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List all contact groups"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let service = Services.contacts()
        let groups = try await service.getGroups()

        if json {
            try OutputFormatter.printJSON(groups)
        } else {
            if groups.isEmpty {
                print("No contact groups found")
            } else {
                print("Contact Groups (\(groups.count)):")
                for group in groups {
                    print("  \(group.name) (ID: \(group.identifier))")
                }
            }
        }
    }
}

struct ContactsGroupsMembers: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "members",
        abstract: "List members of a contact group"
    )

    @Argument(help: "Group identifier")
    var groupId: String

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let service = Services.contacts()
        let members = try await service.getGroupMembers(groupIdentifier: groupId)

        if json {
            try OutputFormatter.printJSON(members)
        } else {
            if members.isEmpty {
                print("Group has no members")
            } else {
                print("Group Members (\(members.count)):")
                for member in members {
                    print("  \(member.fullName)")
                    if !member.emails.isEmpty {
                        print("    Email: \(member.emails[0])")
                    }
                }
            }
        }
    }
}

struct ContactsGroupsAddMember: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "add-member",
        abstract: "Add a contact to a group"
    )

    @Argument(help: "Group identifier")
    var groupId: String

    @Argument(help: "Contact identifier")
    var contactId: String

    func run() async throws {
        let service = Services.contacts()
        let success = try await service.addContactToGroup(contactIdentifier: contactId, groupIdentifier: groupId)

        if success {
            print("Added contact to group")
        } else {
            print("Failed to add contact to group")
        }
    }
}

struct ContactsGroupsRemoveMember: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "remove-member",
        abstract: "Remove a contact from a group"
    )

    @Argument(help: "Group identifier")
    var groupId: String

    @Argument(help: "Contact identifier")
    var contactId: String

    func run() async throws {
        let service = Services.contacts()
        let success = try await service.removeContactFromGroup(contactIdentifier: contactId, groupIdentifier: groupId)

        if success {
            print("Removed contact from group")
        } else {
            print("Failed to remove contact from group")
        }
    }
}

struct ContactsGroupsRename: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "rename",
        abstract: "Rename a contact group"
    )

    @Argument(help: "Group identifier")
    var groupId: String

    @Option(name: .long, help: "New group name")
    var newName: String

    func run() async throws {
        let service = Services.contacts()
        let success = try await service.renameGroup(groupIdentifier: groupId, newName: newName)

        if success {
            print("Renamed group to '\(newName)'")
        } else {
            print("Failed to rename group")
        }
    }
}
