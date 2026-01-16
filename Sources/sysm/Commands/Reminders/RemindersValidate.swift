import ArgumentParser
import Foundation

struct RemindersValidate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "validate",
        abstract: "Find reminders with invalid dates"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let service = Services.reminders()
        let invalid = try await service.validateReminders()

        if json {
            try OutputFormatter.printJSON(invalid)
        } else {
            if invalid.isEmpty {
                print("No reminders with invalid dates found")
            } else {
                print("Found \(invalid.count) reminder(s) with invalid dates:")
                for reminder in invalid {
                    print("  [\(reminder.listName)] \(reminder.title) - \(reminder.dueDateString ?? "unknown")")
                }
            }
        }
    }
}
