import ArgumentParser
import Foundation
import SysmCore

struct RemindersList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List reminders"
    )

    @Argument(help: "List name (optional, shows all if omitted)")
    var listName: String?

    @Flag(name: .long, help: "Include completed reminders")
    var all = false

    @Flag(name: .long, help: "Show additional details (notes, URL, recurrence)")
    var details = false

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let service = Services.reminders()
        let reminders = try await service.getReminders(listName: listName, includeCompleted: all)

        if json {
            try OutputFormatter.printJSON(reminders)
        } else {
            if reminders.isEmpty {
                let completedNote = all ? "" : " incomplete"
                print("No\(completedNote) reminders")
            } else {
                let label = listName ?? "All"
                let completedNote = all ? ", including completed" : ""
                print("Reminders (\(label)\(completedNote)):")
                for reminder in reminders {
                    print("  \(reminder.formatted(includeList: listName == nil, showDetails: details))")
                }
            }
        }
    }
}
