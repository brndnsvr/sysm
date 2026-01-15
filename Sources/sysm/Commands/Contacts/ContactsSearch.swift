import ArgumentParser
import Foundation

struct ContactsSearch: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "search",
        abstract: "Search contacts by name"
    )

    @Argument(help: "Name to search for")
    var query: String

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let service = Services.contacts()
        let contacts = try await service.search(query: query)

        if json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(contacts)
            if let jsonString = String(data: data, encoding: .utf8) {
                print(jsonString)
            }
        } else {
            if contacts.isEmpty {
                print("No contacts found for '\(query)'")
            } else {
                print("Contacts (\(contacts.count)):")
                for contact in contacts {
                    print("\n  \(contact.fullName)")
                    print("  ID: \(contact.identifier)")
                    if let org = contact.organization {
                        print("  Organization: \(org)")
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
