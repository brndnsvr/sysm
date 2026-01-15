import ArgumentParser
import Foundation

struct ContactsGroups: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "groups",
        abstract: "List contact groups"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let service = Services.contacts()
        let groups = try await service.getGroups()

        if json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(groups)
            if let jsonString = String(data: data, encoding: .utf8) {
                print(jsonString)
            }
        } else {
            if groups.isEmpty {
                print("No contact groups found")
            } else {
                print("Contact Groups (\(groups.count)):")
                for group in groups {
                    print("  - \(group.name)")
                }
            }
        }
    }
}
