import ArgumentParser
import Foundation
import SysmCore

struct RemindersSync: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "sync",
        abstract: "Sync tracked reminders to TRIGGER.md"
    )

    func run() async throws {
        let cache = CacheService()
        let trigger = TriggerService()

        let tracked = cache.getTrackedReminders()
        try trigger.syncTrackedReminders(tracked)

        let activeCount = tracked.filter { $0.reminder.status != "done" }.count
        print("Synced \(activeCount) active reminder(s) to TRIGGER.md")
    }
}
