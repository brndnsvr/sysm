import ArgumentParser
import Foundation
import SysmCore

struct CalendarAdd: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "add",
        abstract: "Add a new calendar event"
    )

    @Argument(help: "Event title")
    var title: String

    @Option(name: .long, help: "Start date/time (e.g., 'tomorrow 2pm', 'next monday 10:00')")
    var start: String

    @Option(name: .long, help: "End date/time (defaults to 1 hour after start)")
    var end: String?

    @Option(name: .long, help: "Calendar name (uses default calendar if not specified)")
    var calendar: String?

    @Option(name: .long, help: "Event location")
    var location: String?

    @Option(name: .long, help: "Location latitude (requires longitude)")
    var latitude: Double?

    @Option(name: .long, help: "Location longitude (requires latitude)")
    var longitude: Double?

    @Option(name: .long, help: "Location radius in meters (default: 100)")
    var radius: Double?

    // Note: EventKit limitation - attendees can only be read, not added programmatically on macOS
    // This option is kept for future compatibility but currently has no effect
    @Option(name: .long, parsing: .upToNextOption, help: "Attendee email addresses (note: macOS EventKit limitation - attendees cannot be added programmatically)")
    var attendee: [String] = []

    @Option(name: .long, help: "Event notes")
    var notes: String?

    @Option(name: .long, help: "URL associated with the event")
    var url: String?

    @Flag(name: .long, help: "Create as all-day event")
    var allDay = false

    // Recurrence options
    @Option(name: .long, help: "Repeat frequency: daily, weekly, monthly, yearly")
    var repeats: RecurrenceFrequency?

    @Option(name: .long, help: "Repeat interval (e.g., 2 for every 2 weeks)")
    var repeatInterval: Int?

    @Option(name: .long, help: "End date for recurring events")
    var repeatUntil: String?

    @Option(name: .long, help: "Number of occurrences for recurring events")
    var repeatCount: Int?

    // Alarm options
    @Option(name: .long, parsing: .upToNextOption, help: "Reminder times in minutes before event (e.g., --remind 15 60 for 15min and 1hr)")
    var remind: [Int] = []

    // Availability
    @Option(name: .long, help: "Show as: busy, free, tentative, unavailable")
    var showAs: EventAvailability?

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        // Warn if attendees specified (EventKit limitation)
        if !attendee.isEmpty {
            print("Warning: macOS EventKit does not support adding attendees programmatically.")
            print("Attendees can only be added through Calendar.app or calendar invitations.")
        }

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
        } else if allDay {
            guard let nextDay = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: startDate)) else {
                throw CalendarError.invalidDateFormat("Unable to calculate end date")
            }
            endDate = nextDay
        } else {
            guard let oneHourLater = cal.date(byAdding: .hour, value: 1, to: startDate) else {
                throw CalendarError.invalidDateFormat("Unable to calculate end date")
            }
            endDate = oneHourLater
        }

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

        // Build structured location if coordinates provided
        var structuredLocation: StructuredLocation? = nil
        if let lat = latitude, let lon = longitude {
            let locTitle = location ?? "Location"
            structuredLocation = StructuredLocation(
                title: locTitle,
                address: nil,
                latitude: lat,
                longitude: lon,
                radius: radius ?? 100.0
            )
        }

        let service = Services.calendar()
        let event = try await service.addEvent(
            title: title,
            startDate: allDay ? cal.startOfDay(for: startDate) : startDate,
            endDate: endDate,
            calendarName: calendar,
            location: location,
            notes: notes,
            isAllDay: allDay,
            recurrence: recurrence,
            alarmMinutes: remind.isEmpty ? nil : remind,
            url: url,
            availability: showAs,
            attendeeEmails: attendee.isEmpty ? nil : attendee,
            structuredLocation: structuredLocation
        )

        if json {
            try OutputFormatter.printJSON(event)
        } else {
            let formatter = allDay ? DateFormatters.fullDate : DateFormatters.fullDateTime
            print("Created event: \(event.title)")
            print("  Calendar: \(event.calendarName)")
            print("  Start: \(formatter.string(from: event.startDate))")
            print("  End: \(formatter.string(from: event.endDate))")
            if let loc = event.location, !loc.isEmpty {
                print("  Location: \(loc)")
                if let structLoc = event.structuredLocation, let lat = structLoc.latitude, let lon = structLoc.longitude {
                    print("    Coordinates: \(lat), \(lon)")
                }
            }
            if let attendeeList = event.attendees, !attendeeList.isEmpty {
                print("  Attendees: \(attendeeList.map { $0.email ?? $0.name ?? "Unknown" }.joined(separator: ", "))")
            }
            if let rule = event.recurrenceRule {
                print("  Repeats: \(rule.description)")
            }
            if let alarms = event.alarms, !alarms.isEmpty {
                print("  Reminders: \(alarms.map { $0.description }.joined(separator: ", "))")
            }
        }
    }
}
