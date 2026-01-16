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
        let service = Services.reminders()
        let lists = try await service.listNames()

        if json {
            try OutputFormatter.printJSON(lists)
        } else {
            print("Reminder Lists:")
            for list in lists {
                print("  - \(list)")
            }
        }
    }
}
