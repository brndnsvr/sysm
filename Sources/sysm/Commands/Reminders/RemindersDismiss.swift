import ArgumentParser
import Foundation

struct RemindersDismiss: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "dismiss",
        abstract: "Mark a reminder as seen but not tracked"
    )

    @Argument(help: "Reminder name")
    var name: String

    func run() async throws {
        let cache = CacheService()
        try cache.dismissReminder(name: name)
        print("Dismissed: \(name)")
    }
}
