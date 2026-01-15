import ArgumentParser
import Foundation

struct RemindersAdd: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "add",
        abstract: "Add a new reminder"
    )

    @Argument(help: "Reminder text")
    var task: String

    @Option(name: .shortAndLong, help: "Target list name")
    var list: String = "Reminders"

    @Option(name: .shortAndLong, help: "Due date (YYYY-MM-DD)")
    var due: String?

    @Flag(name: .shortAndLong, help: "Minimal output")
    var quiet = false

    func run() async throws {
        let service = Services.reminders()

        do {
            let reminder = try await service.addReminder(title: task, listName: list, dueDate: due)

            if quiet {
                print("✓")
            } else {
                var msg = "Added: \(task) to \(list)"
                if let dueDate = reminder.dueDateISO {
                    msg += " (due: \(dueDate))"
                }
                print(msg)
            }
        } catch ReminderError.invalidYear(let year) {
            fputs("Error: Year \(year) out of valid range (2000-2100)\n", stderr)
            throw ExitCode.failure
        }
    }
}
