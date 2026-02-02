import ArgumentParser
import Foundation
import SysmCore

struct RemindersAdd: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "add",
        abstract: "Add a new reminder"
    )

    @Argument(help: "Reminder text")
    var task: String

    @Option(name: .shortAndLong, help: "Target list name")
    var list: String = "Reminders"

    @Option(name: .shortAndLong, help: "Due date (e.g., 'tomorrow 2pm', 'next monday', 'YYYY-MM-DD')")
    var due: String?

    @Option(name: .shortAndLong, help: "Priority: 1=high, 5=medium, 9=low, 0=none")
    var priority: Int?

    @Option(name: .shortAndLong, help: "Notes for the reminder")
    var notes: String?

    @Option(name: .long, help: "URL associated with the reminder")
    var url: String?

    @Option(name: .long, help: "Repeat frequency: daily, weekly, monthly, yearly")
    var repeats: RecurrenceFrequency?

    @Option(name: .long, help: "Repeat interval (e.g., 2 for every 2 weeks)")
    var repeatInterval: Int?

    @Option(name: .long, help: "End date for recurring reminders")
    var repeatUntil: String?

    @Option(name: .long, help: "Number of occurrences for recurring reminders")
    var repeatCount: Int?

    @Flag(name: .shortAndLong, help: "Minimal output")
    var quiet = false

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let service = Services.reminders()

        // Build recurrence rule if specified
        var recurrence: RecurrenceRule? = nil
        if let frequency = repeats {
            var recEndDate: Date? = nil
            if let untilStr = repeatUntil {
                recEndDate = Services.dateParser().parse(untilStr)
            }
            recurrence = RecurrenceRule(
                frequency: frequency,
                interval: repeatInterval ?? 1,
                daysOfWeek: nil,
                endDate: recEndDate,
                occurrenceCount: repeatCount
            )
        }

        do {
            let reminder = try await service.addReminder(
                title: task,
                listName: list,
                dueDate: due,
                priority: priority,
                notes: notes,
                url: url,
                recurrence: recurrence
            )

            if json {
                try OutputFormatter.printJSON(reminder)
            } else if quiet {
                print("✓")
            } else {
                print("Added: \(task) to \(list)")
                if let dueDate = reminder.dueDateString {
                    print("  Due: \(dueDate)")
                }
                if reminder.priorityLevel != .none {
                    print("  Priority: \(reminder.priorityLevel.description)")
                }
                if let rule = reminder.recurrenceRule {
                    print("  Repeats: \(rule.description)")
                }
                if let reminderNotes = reminder.notes, !reminderNotes.isEmpty {
                    print("  Notes: \(reminderNotes)")
                }
                if let reminderUrl = reminder.url {
                    print("  URL: \(reminderUrl)")
                }
            }
        } catch {
            fputs("Error: \(error.localizedDescription)\n", stderr)
            throw ExitCode.failure
        }
    }
}
