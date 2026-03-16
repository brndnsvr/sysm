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

    @Option(name: .long, parsing: .upToNextOption, help: "Attendee email addresses (sends invitations via CalDAV)")
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
        // Validate CalDAV is configured if attendees are requested
        if !attendee.isEmpty {
            let caldav = Services.caldav()
            guard caldav.isConfigured() else {
                throw CalDAVError.notConfigured
            }
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

        // Add attendees via CalDAV if requested
        var attendeesAdded = false
        if !attendee.isEmpty {
            let caldav = Services.caldav()
            var externalID = event.externalID

            // If externalID is nil, the event may not have synced to iCloud yet
            if externalID == nil {
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                if let refreshed = try await service.getEvent(id: event.id) {
                    externalID = refreshed.externalID
                }
            }

            if let uid = externalID {
                do {
                    try await caldav.addAttendees(
                        emails: attendee,
                        toEventUID: uid,
                        calendarName: calendar,
                        organizerEmail: nil
                    )
                    attendeesAdded = true
                } catch {
                    if !json {
                        print("Warning: Event created but attendee invitations failed: \(error.localizedDescription)")
                        print("  Try: sysm calendar invite \(event.id) --attendee \(attendee.joined(separator: " --attendee "))")
                    }
                }
            } else if !json {
                print("Warning: Event created but iCloud sync pending — attendees not added yet.")
                print("  Try: sysm calendar invite \(event.id) --attendee \(attendee.joined(separator: " --attendee "))")
            }
        }

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
            if attendeesAdded {
                print("  Attendees invited: \(attendee.joined(separator: ", "))")
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
