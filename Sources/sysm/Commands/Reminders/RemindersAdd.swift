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

    @Option(name: .long, help: "Start date (e.g., 'tomorrow 9am', 'next monday', 'YYYY-MM-DD')")
    var start: String?

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

    @Option(name: .long, help: "Days of month for monthly recurrence (e.g., 1,15 for 1st and 15th)")
    var repeatDaysOfMonth: [Int] = []

    @Option(name: .long, help: "Months for yearly recurrence (1-12, e.g., 3,6,9,12 for quarterly)")
    var repeatMonths: [Int] = []

    @Option(name: .long, help: "Week positions for recurrence (e.g., 1 for first, -1 for last)")
    var repeatPositions: [Int] = []

    @Option(name: .long, help: "End date for recurring reminders")
    var repeatUntil: String?

    @Option(name: .long, help: "Number of occurrences for recurring reminders")
    var repeatCount: Int?

    @Option(name: .long, parsing: .remaining, help: "Alarm offset in minutes (e.g., 15 for 15 minutes before, can be repeated for multiple alarms)")
    var alarm: [Int] = []

    @Option(name: .long, help: "Location name for location-based alarm")
    var location: String?

    @Option(name: .long, help: "Location latitude for geofencing")
    var locationLatitude: Double?

    @Option(name: .long, help: "Location longitude for geofencing")
    var locationLongitude: Double?

    @Option(name: .long, help: "Location radius in meters (default: 100)")
    var locationRadius: Double?

    @Option(name: .long, help: "Location trigger: enter or leave")
    var locationTrigger: String?

    @Option(name: .long, help: "Tags for the reminder (space-separated, e.g., work urgent)")
    var tags: [String] = []

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
                daysOfTheMonth: repeatDaysOfMonth.isEmpty ? nil : repeatDaysOfMonth,
                monthsOfTheYear: repeatMonths.isEmpty ? nil : repeatMonths,
                weeksOfTheYear: nil,
                daysOfTheYear: nil,
                setPositions: repeatPositions.isEmpty ? nil : repeatPositions,
                endDate: recEndDate,
                occurrenceCount: repeatCount
            )
        }

        // Build alarms if specified
        var alarms: [EventAlarm]? = nil
        var alarmList: [EventAlarm] = []

        // Add time-based alarms
        if !alarm.isEmpty {
            alarmList.append(contentsOf: alarm.map { EventAlarm(triggerMinutes: $0) })
        }

        // Add location-based alarm if specified
        if let locationName = location, let trigger = locationTrigger {
            let structuredLocation = StructuredLocation(
                title: locationName,
                address: nil,
                latitude: locationLatitude,
                longitude: locationLongitude,
                radius: locationRadius ?? 100.0
            )
            alarmList.append(EventAlarm(location: structuredLocation, proximity: trigger))
        }

        if !alarmList.isEmpty {
            alarms = alarmList
        }

        // Add tags to notes if specified
        var finalNotes = notes
        if !tags.isEmpty {
            finalNotes = TagHelper.addTags(tags, to: notes)
        }

        do {
            let reminder = try await service.addReminder(
                title: task,
                listName: list,
                startDate: start,
                dueDate: due,
                priority: priority,
                notes: finalNotes,
                url: url,
                recurrence: recurrence,
                alarms: alarms
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
                if let alarmsList = reminder.alarms, !alarmsList.isEmpty {
                    for alarm in alarmsList {
                        print("  Alarm: \(alarm.description)")
                    }
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
