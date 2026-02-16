import ArgumentParser
import Foundation
import SysmCore

struct ContactsAdd: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "add",
        abstract: "Add a new contact"
    )

    @Option(name: .long, help: "First name")
    var firstName: String?

    @Option(name: .long, help: "Last name")
    var lastName: String?

    @Option(name: .long, help: "Company/organization name")
    var organization: String?

    @Option(name: .long, help: "Job title")
    var jobTitle: String?

    @Option(name: .long, parsing: .upToNextOption, help: "Email addresses (can specify multiple)")
    var email: [String] = []

    @Option(name: .long, parsing: .upToNextOption, help: "Phone numbers (can specify multiple)")
    var phone: [String] = []

    @Option(name: .long, help: "Notes about the contact")
    var notes: String?

    @Option(name: .long, help: "Website URL")
    var url: String?

    @Option(name: .long, help: "Birthday (YYYY-MM-DD or MM-DD)")
    var birthday: String?

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func validate() throws {
        if firstName == nil && lastName == nil && organization == nil {
            throw ValidationError("At least --first-name, --last-name, or --organization is required")
        }
    }

    func run() async throws {
        let service = Services.contacts()

        // Parse birthday if provided
        var birthdayComponents: DateComponents?
        if let birthdayStr = birthday {
            let parts = birthdayStr.split(separator: "-").compactMap { Int($0) }
            if parts.count == 3 {
                // YYYY-MM-DD
                birthdayComponents = DateComponents(year: parts[0], month: parts[1], day: parts[2])
            } else if parts.count == 2 {
                // MM-DD (no year)
                birthdayComponents = DateComponents(month: parts[0], day: parts[1])
            } else {
                fputs("Error: Invalid birthday format. Use YYYY-MM-DD or MM-DD\n", stderr)
                throw ExitCode.failure
            }
        }

        // Convert simple string arrays to labeled tuples
        let emails: [(label: String?, value: String)]? = email.isEmpty ? nil : email.map { (nil, $0) }
        let phones: [(label: String?, value: String)]? = phone.isEmpty ? nil : phone.map { (nil, $0) }
        let urls: [(label: String?, value: String)]? = url != nil ? [(nil, url!)] : nil

        do {
            let contact = try await service.createContact(
                givenName: firstName,
                familyName: lastName,
                organization: organization,
                jobTitle: jobTitle,
                emails: emails,
                phones: phones,
                addresses: nil,
                birthday: birthdayComponents,
                note: notes,
                urls: urls,
                socialProfiles: nil,
                relations: nil
            )

            if json {
                try OutputFormatter.printJSON(contact)
            } else {
                print("Created contact: \(contact.fullName.isEmpty ? contact.organization ?? "Contact" : contact.fullName)")
                print("  ID: \(contact.identifier)")
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
