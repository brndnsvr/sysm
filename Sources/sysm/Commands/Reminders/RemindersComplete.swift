import ArgumentParser
import Foundation
import SysmCore

struct RemindersComplete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "complete",
        abstract: "Mark a reminder as complete"
    )

    @Argument(help: "Reminder name")
    var name: String

    func run() async throws {
        let service = Services.reminders()
        let completed = try await service.completeReminder(name: name)

        if completed {
            print("Completed: \(name)")
        } else {
            fputs("Not found: \(name)\n", stderr)
            throw ExitCode.failure
        }
    }
}
