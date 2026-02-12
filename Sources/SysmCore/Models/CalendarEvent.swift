import EventKit
import Foundation

/// Represents a calendar event from macOS Calendar.
///
/// This model wraps EventKit's `EKEvent` for JSON serialization and
/// provides convenient formatting methods for CLI output.
public struct CalendarEvent: Codable {
    public let id: String
    public let title: String
    public let calendarName: String
    public let startDate: Date
    public let endDate: Date
    public let isAllDay: Bool
    public let location: String?
    public let notes: String?
    public let url: String?
    public let availability: EventAvailability
    public let recurrenceRule: RecurrenceRule?
    public let attendees: [EventAttendee]?
    public let alarms: [EventAlarm]?
    public let hasRecurrence: Bool
    public let organizerName: String?

    /// Creates a CalendarEvent from an EventKit event.
    /// - Parameter ekEvent: The EventKit event to convert.
    public init(from ekEvent: EKEvent) {
        self.id = ekEvent.eventIdentifier ?? UUID().uuidString
        self.title = ekEvent.title ?? ""
        self.calendarName = ekEvent.calendar?.title ?? "Unknown"
        self.startDate = ekEvent.startDate
        self.endDate = ekEvent.endDate
        self.isAllDay = ekEvent.isAllDay
        self.location = ekEvent.location
        self.notes = ekEvent.notes
        self.url = ekEvent.url?.absoluteString
        self.availability = EventAvailability(from: ekEvent.availability)
        self.hasRecurrence = ekEvent.hasRecurrenceRules

        if let rules = ekEvent.recurrenceRules, let firstRule = rules.first {
            self.recurrenceRule = RecurrenceRule(from: firstRule)
        } else {
            self.recurrenceRule = nil
        }

        if let participants = ekEvent.attendees, !participants.isEmpty {
            self.attendees = participants.map { EventAttendee(from: $0) }
        } else {
            self.attendees = nil
        }

        if let ekAlarms = ekEvent.alarms, !ekAlarms.isEmpty {
            self.alarms = ekAlarms.map { EventAlarm(from: $0) }
        } else {
            self.alarms = nil
        }

        self.organizerName = ekEvent.organizer?.name
    }

    /// Formatted time range string (e.g., "10:00 AM - 11:00 AM" or "All day").
    public var timeRange: String {
        if isAllDay {
            return "All day"
        }
        return "\(DateFormatters.shortTime.string(from: startDate)) - \(DateFormatters.shortTime.string(from: endDate))"
    }

    /// Full date string for the event's start date.
    public var dateString: String {
        DateFormatters.mediumDate.string(from: startDate)
    }

    /// Formats the event for CLI display.
    /// - Parameter showCalendar: Whether to include the calendar name.
    /// - Parameter showDetails: Whether to show recurrence, attendees, and alarms.
    /// - Returns: Formatted string with time, title, location, and optionally calendar.
    public func formatted(showCalendar: Bool = false, showDetails: Bool = false) -> String {
        var result = "- \(timeRange): \(title)"
        if let loc = location, !loc.isEmpty {
            result += " @ \(loc)"
        }
        if hasRecurrence {
            result += " [repeating]"
        }
        if showCalendar {
            result += " [\(calendarName)]"
        }
        if showDetails {
            if let rule = recurrenceRule {
                result += "\n    Recurrence: \(rule.description)"
            }
            if let attendeeList = attendees, !attendeeList.isEmpty {
                result += "\n    Attendees: \(attendeeList.count)"
                for attendee in attendeeList {
                    result += "\n      \(attendee.formatted)"
                }
            }
            if let alarmList = alarms, !alarmList.isEmpty {
                result += "\n    Reminders: \(alarmList.map { $0.description }.joined(separator: ", "))"
            }
        }
        return result
    }

    /// Full detailed description for single event view.
    public var detailedDescription: String {
        var lines: [String] = []
        lines.append("Title: \(title)")
        lines.append("Calendar: \(calendarName)")
        lines.append("Date: \(dateString)")
        lines.append("Time: \(timeRange)")

        if let loc = location, !loc.isEmpty {
            lines.append("Location: \(loc)")
        }
        if let eventUrl = url {
            lines.append("URL: \(eventUrl)")
        }
        lines.append("Availability: \(availability.rawValue)")

        if let rule = recurrenceRule {
            lines.append("Recurrence: \(rule.description)")
        }

        if let alarmList = alarms, !alarmList.isEmpty {
            lines.append("Reminders: \(alarmList.map { $0.description }.joined(separator: ", "))")
        }

        if let attendeeList = attendees, !attendeeList.isEmpty {
            lines.append("Attendees (\(attendeeList.count)):")
            for attendee in attendeeList {
                lines.append("  \(attendee.formatted)")
            }
        }

        if let eventNotes = notes, !eventNotes.isEmpty {
            lines.append("Notes: \(eventNotes)")
        }

        return lines.joined(separator: "\n")
    }
}
