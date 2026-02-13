import ArgumentParser
import Foundation
import SysmCore

struct CalendarConflicts: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "conflicts",
        abstract: "Detect scheduling conflicts for a time slot"
    )

    @Option(name: .long, help: "Start date/time (e.g., 'tomorrow 2pm', 'next monday 10:00')")
    var start: String

    @Option(name: .long, help: "End date/time (defaults to 1 hour after start)")
    var end: String?

    @Option(name: .long, help: "Calendar name to check (checks all if not specified)")
    var calendar: String?

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        guard let startDate = Services.dateParser().parse(start) else {
            throw CalendarError.invalidDateFormat(start)
        }

        let cal = Foundation.Calendar.current
        let endDate: Date
        if let endStr = end {
            guard let parsed = Services.dateParser().parse(endStr) else {
                throw CalendarError.invalidDateFormat(endStr)
            }
            endDate = parsed
        } else {
            guard let oneHourLater = cal.date(byAdding: .hour, value: 1, to: startDate) else {
                throw CalendarError.invalidDateFormat("Unable to calculate end date")
            }
            endDate = oneHourLater
        }

        let service = Services.calendar()
        let conflicts = try await service.detectConflicts(
            startDate: startDate,
            endDate: endDate,
            calendarName: calendar
        )

        if json {
            try OutputFormatter.printJSON(conflicts)
        } else {
            let timeRange = "\(DateFormatters.shortTime.string(from: startDate)) - \(DateFormatters.shortTime.string(from: endDate))"
            let dateStr = DateFormatters.mediumDate.string(from: startDate)

            if conflicts.isEmpty {
                print("No conflicts found for \(dateStr) at \(timeRange)")
                if calendar == nil {
                    print("Time slot is available across all calendars")
                } else {
                    print("Time slot is available in calendar '\(calendar!)'")
                }
            } else {
                print("Found \(conflicts.count) conflict(s) for \(dateStr) at \(timeRange):")
                print()
                for conflict in conflicts {
                    print("  \(conflict.formatted(showCalendar: true))")
                }
                print()
                print("Suggestion: Consider scheduling at a different time")

                // Suggest alternative time slots
                suggestAlternatives(around: startDate, duration: endDate.timeIntervalSince(startDate))
            }
        }
    }

    private func suggestAlternatives(around date: Date, duration: TimeInterval) {
        let cal = Foundation.Calendar.current
        print("\nAlternative time slots on the same day:")

        // Suggest earlier slots
        if let twoHoursBefore = cal.date(byAdding: .hour, value: -2, to: date),
           cal.isDate(twoHoursBefore, inSameDayAs: date) {
            let endTime = twoHoursBefore.addingTimeInterval(duration)
            print("  - \(DateFormatters.shortTime.string(from: twoHoursBefore)) - \(DateFormatters.shortTime.string(from: endTime))")
        }

        if let oneHourBefore = cal.date(byAdding: .hour, value: -1, to: date),
           cal.isDate(oneHourBefore, inSameDayAs: date) {
            let endTime = oneHourBefore.addingTimeInterval(duration)
            print("  - \(DateFormatters.shortTime.string(from: oneHourBefore)) - \(DateFormatters.shortTime.string(from: endTime))")
        }

        // Suggest later slots
        if let oneHourAfter = cal.date(byAdding: .hour, value: 1, to: date),
           cal.isDate(oneHourAfter, inSameDayAs: date) {
            let endTime = oneHourAfter.addingTimeInterval(duration)
            print("  - \(DateFormatters.shortTime.string(from: oneHourAfter)) - \(DateFormatters.shortTime.string(from: endTime))")
        }

        if let twoHoursAfter = cal.date(byAdding: .hour, value: 2, to: date),
           cal.isDate(twoHoursAfter, inSameDayAs: date) {
            let endTime = twoHoursAfter.addingTimeInterval(duration)
            print("  - \(DateFormatters.shortTime.string(from: twoHoursAfter)) - \(DateFormatters.shortTime.string(from: endTime))")
        }
    }
}
