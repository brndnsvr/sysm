import ArgumentParser
import Foundation
import SysmCore

struct ContactsEdit: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "edit",
        abstract: "Edit an existing contact"
    )

    @Argument(help: "Contact identifier (use 'sysm contacts search --json' to find IDs)")
    var identifier: String

    @Option(name: .long, help: "New first name")
    var firstName: String?

    @Option(name: .long, help: "New last name")
    var lastName: String?

    @Option(name: .long, help: "New company/organization name")
    var organization: String?

    @Option(name: .long, help: "New job title")
    var jobTitle: String?

    @Option(name: .long, parsing: .upToNextOption, help: "New email addresses (replaces existing)")
    var email: [String] = []

    @Option(name: .long, parsing: .upToNextOption, help: "New phone numbers (replaces existing)")
    var phone: [String] = []

    @Option(name: .long, help: "New notes")
    var notes: String?

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let service = Services.contacts()

        // Convert simple string arrays to labeled tuples
        let emails: [(label: String?, value: String)]? = email.isEmpty ? nil : email.map { (nil, $0) }
        let phones: [(label: String?, value: String)]? = phone.isEmpty ? nil : phone.map { (nil, $0) }

        do {
            let contact = try await service.updateContact(
                identifier: identifier,
                givenName: firstName,
                familyName: lastName,
                organization: organization,
                jobTitle: jobTitle,
                emails: emails,
                phones: phones,
                note: notes
            )

            if json {
                try OutputFormatter.printJSON(contact)
            } else {
                print("Updated contact: \(contact.fullName.isEmpty ? contact.organization ?? "Contact" : contact.fullName)")
                if !contact.emails.isEmpty {
                    print("  Emails: \(contact.emails.joined(separator: ", "))")
                }
                if !contact.phones.isEmpty {
                    print("  Phones: \(contact.phones.joined(separator: ", "))")
                }
                if let org = contact.organization {
                    print("  Organization: \(org)")
                }
            }
        } catch {
            fputs("Error: \(error.localizedDescription)\n", stderr)
            throw ExitCode.failure
        }
    }
}
