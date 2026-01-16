import ArgumentParser
import Foundation

struct RemindersList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List incomplete reminders"
    )

    @Argument(help: "List name (optional, shows all if omitted)")
    var listName: String?

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let service = Services.reminders()
        let reminders = try await service.getReminders(listName: listName)

        if json {
            try OutputFormatter.printJSON(reminders)
        } else {
            if reminders.isEmpty {
                print("No incomplete reminders")
            } else {
                let label = listName ?? "All"
                print("Reminders (\(label)):")
                for reminder in reminders {
                    print("  \(reminder.formatted())")
                }
            }
        }
    }
}
