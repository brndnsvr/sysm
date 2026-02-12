import ArgumentParser
import Foundation
import SysmCore

struct RemindersEdit: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "edit",
        abstract: "Edit an existing reminder"
    )

    @Argument(help: "Reminder ID (use 'sysm reminders list --json' to find IDs)")
    var id: String

    @Option(name: .shortAndLong, help: "New title")
    var title: String?

    @Option(name: .long, help: "New start date (e.g., 'tomorrow 9am', 'next monday', 'YYYY-MM-DD')")
    var start: String?

    @Option(name: .shortAndLong, help: "New due date (e.g., 'tomorrow 2pm', 'next monday', 'YYYY-MM-DD')")
    var due: String?

    @Option(name: .shortAndLong, help: "New priority: 1=high, 5=medium, 9=low, 0=none")
    var priority: Int?

    @Option(name: .shortAndLong, help: "New notes")
    var notes: String?

    @Option(name: .long, help: "New alarms in minutes (replaces all existing alarms, can be repeated)")
    var alarm: [Int] = []

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let service = Services.reminders()

        // Build alarms if specified
        var alarms: [EventAlarm]? = nil
        if !alarm.isEmpty {
            alarms = alarm.map { EventAlarm(triggerMinutes: $0) }
        }

        do {
            let reminder = try await service.editReminder(
                id: id,
                newTitle: title,
                newStartDate: start,
                newDueDate: due,
                newPriority: priority,
                newNotes: notes,
                newAlarms: alarms
            )

            if json {
                try OutputFormatter.printJSON(reminder)
            } else {
                print("Updated: \(reminder.title)")
                if let dueDate = reminder.dueDateString {
                    print("  Due: \(dueDate)")
                }
                if reminder.priorityLevel != .none {
                    print("  Priority: \(reminder.priorityLevel.description)")
                }
                if let alarmsList = reminder.alarms, !alarmsList.isEmpty {
                    for alarm in alarmsList {
                        print("  Alarm: \(alarm.description)")
                    }
                }
                if let reminderNotes = reminder.notes, !reminderNotes.isEmpty {
                    print("  Notes: \(reminderNotes)")
                }
            }
        } catch {
            fputs("Error: \(error.localizedDescription)\n", stderr)
            throw ExitCode.failure
        }
    }
}
