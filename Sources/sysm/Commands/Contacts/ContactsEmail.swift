import ArgumentParser
import Foundation
import SysmCore

struct ContactsEmail: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "email",
        abstract: "Search contacts by email or get emails for a name"
    )

    @Argument(help: "Name or email to search for")
    var query: String

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let service = Services.contacts()
        let results = try await service.searchByEmail(query: query)

        if json {
            let jsonResults = results.map { ["name": $0.name, "email": $0.email] }
            try OutputFormatter.printJSON(jsonResults)
        } else {
            if results.isEmpty {
                print("No email addresses found for '\(query)'")
            } else {
                print("Email addresses (\(results.count)):")
                for result in results {
                    print("  \(result.name): \(result.email)")
                }
            }
        }
    }
}
