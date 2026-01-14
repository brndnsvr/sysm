import ArgumentParser
import Foundation

struct ContactsPhone: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "phone",
        abstract: "Search contacts by phone number or get phones for a name"
    )

    @Argument(help: "Name or phone number to search for")
    var query: String

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let service = ContactsService()
        let results = try await service.searchByPhone(query: query)

        if json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let jsonResults = results.map { ["name": $0.name, "phone": $0.phone] }
            let data = try encoder.encode(jsonResults)
            if let jsonString = String(data: data, encoding: .utf8) {
                print(jsonString)
            }
        } else {
            if results.isEmpty {
                print("No phone numbers found for '\(query)'")
            } else {
                print("Phone numbers (\(results.count)):")
                for result in results {
                    print("  \(result.name): \(result.phone)")
                }
            }
        }
    }
}
