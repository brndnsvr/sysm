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
        let service = ReminderService()
        let reminders = try await service.getTodayReminders()

        if json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(reminders)
            print(String(data: data, encoding: .utf8)!)
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
