import ArgumentParser
import Foundation

struct RemindersLists: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "lists",
        abstract: "List all reminder lists"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let service = ReminderService()
        let lists = try await service.listNames()

        if json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(lists)
            print(String(data: data, encoding: .utf8)!)
        } else {
            print("Reminder Lists:")
            for list in lists {
                print("  - \(list)")
            }
        }
    }
}
