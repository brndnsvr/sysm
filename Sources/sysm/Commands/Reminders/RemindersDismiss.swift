import ArgumentParser
import Foundation
import SysmCore

struct RemindersDismiss: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "dismiss",
        abstract: "Mark a reminder as seen but not tracked"
    )

    @Argument(help: "Reminder name")
    var name: String

    func run() async throws {
        let cache = Services.cache()
        try cache.dismissReminder(name: name)
        print("Dismissed: \(name)")
    }
}
