import ArgumentParser
import Foundation
import SysmCore

struct ContactsSearch: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "search",
        abstract: "Search contacts (simple or advanced multi-field search)"
    )

    @Argument(help: "Name to search for (optional if using --company, --job-title, or --email)")
    var query: String?

    @Option(name: .long, help: "Filter by company/organization name")
    var company: String?

    @Option(name: .long, help: "Filter by job title")
    var jobTitle: String?

    @Option(name: .long, help: "Filter by email address")
    var email: String?

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let service = Services.contacts()

        // Use advanced search if any filters are specified
        let contacts: [Contact]
        if company != nil || jobTitle != nil || email != nil {
            contacts = try await service.advancedSearch(
                name: query,
                company: company,
                jobTitle: jobTitle,
                email: email
            )
        } else if let query = query {
            contacts = try await service.search(query: query)
        } else {
            fputs("Error: Provide a name to search or use filters (--company, --job-title, --email)\n", stderr)
            throw ExitCode.failure
        }

        if json {
            try OutputFormatter.printJSON(contacts)
        } else {
            if contacts.isEmpty {
                print("No contacts found")
            } else {
                print("Contacts (\(contacts.count)):")
                for contact in contacts {
                    print("\n  \(contact.fullName)")
                    print("  ID: \(contact.identifier)")
                    if let org = contact.organization {
                        print("  Organization: \(org)")
                    }
                    if let job = contact.jobTitle {
                        print("  Job Title: \(job)")
                    }
                    for email in contact.emails {
                        print("  Email: \(email)")
                    }
                    for phone in contact.phones {
                        print("  Phone: \(phone)")
                    }
                }
            }
        }
    }
}
