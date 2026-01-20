import ArgumentParser
import Foundation
import SysmCore

struct ContactsDelete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a contact"
    )

    @Argument(help: "Contact identifier (use 'sysm contacts search --json' to find IDs)")
    var identifier: String

    @Flag(name: .shortAndLong, help: "Skip confirmation")
    var force = false

    func run() async throws {
        let service = Services.contacts()

        // Show contact info before deleting
        if !force {
            if let contact = try await service.getContact(identifier: identifier) {
                print("About to delete: \(contact.fullName.isEmpty ? contact.organization ?? identifier : contact.fullName)")
                if !contact.emails.isEmpty {
                    print("  Emails: \(contact.emails.joined(separator: ", "))")
                }
                if !contact.phones.isEmpty {
                    print("  Phones: \(contact.phones.joined(separator: ", "))")
                }
            }
            print("Are you sure? (y/N) ", terminator: "")
            guard let response = readLine()?.lowercased(), response == "y" || response == "yes" else {
                print("Cancelled")
                return
            }
        }

        do {
            let success = try await service.deleteContact(identifier: identifier)
            if success {
                print("Contact deleted")
            } else {
                fputs("Contact not found\n", stderr)
                throw ExitCode.failure
            }
        } catch {
            fputs("Error: \(error.localizedDescription)\n", stderr)
            throw ExitCode.failure
        }
    }
}
