import ArgumentParser
import Foundation
import SysmCore

struct RemindersMove: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "move",
        abstract: "Move a reminder to a different list"
    )

    @Argument(help: "Reminder ID (use 'sysm reminders list --json' to find IDs)")
    var id: String

    @Option(name: [.short, .customLong("to")], help: "Target list name")
    var list: String

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let service = Services.reminders()

        do {
            let reminder = try await service.moveReminder(id: id, toList: list)

            if json {
                try OutputFormatter.printJSON(reminder)
            } else {
                print("Moved '\(reminder.title)' to '\(list)'")
                if let dueDate = reminder.dueDateString {
                    print("  Due: \(dueDate)")
                }
            }
        } catch {
            fputs("Error: \(error.localizedDescription)\n", stderr)
            throw ExitCode.failure
        }
    }
}
