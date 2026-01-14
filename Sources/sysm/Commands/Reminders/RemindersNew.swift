import ArgumentParser
import Foundation

struct RemindersNew: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "new",
        abstract: "Show reminders not yet seen/tracked"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let reminderService = ReminderService()
        let cacheService = CacheService()

        let allReminders = try await reminderService.getReminders()
        let newReminders = cacheService.getNewReminders(currentReminders: allReminders)

        if json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(newReminders)
            print(String(data: data, encoding: .utf8)!)
        } else {
            if newReminders.isEmpty {
                print("No new reminders")
            } else {
                print("New Reminders (\(newReminders.count)):")
                for reminder in newReminders {
                    print("  \(reminder.formatted(includeList: true))")
                }
            }
        }
    }
}
