import ArgumentParser
import Foundation

struct RemindersToday: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "today",
        abstract: "List reminders due today"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let service = Services.reminders()
        let reminders = try await service.getTodayReminders()

        if json {
            try OutputFormatter.printJSON(reminders)
        } else {
            if reminders.isEmpty {
                print("No reminders due today")
            } else {
                print("Due Today (\(reminders.count)):")
                for reminder in reminders {
                    print("  \(reminder.formatted())")
                }
            }
        }
    }
}
