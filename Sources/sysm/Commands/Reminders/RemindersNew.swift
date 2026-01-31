import ArgumentParser
import Foundation
import SysmCore

struct RemindersNew: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "new",
        abstract: "Show reminders not yet seen/tracked"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let reminderService = Services.reminders()
        let cacheService = Services.cache()

        let allReminders = try await reminderService.getReminders(listName: nil, includeCompleted: false)
        let newReminders = cacheService.getNewReminders(currentReminders: allReminders)

        if json {
            try OutputFormatter.printJSON(newReminders)
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
