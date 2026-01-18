import EventKit
import Foundation

/// Represents a calendar event from macOS Calendar.
///
/// This model wraps EventKit's `EKEvent` for JSON serialization and
/// provides convenient formatting methods for CLI output.
struct CalendarEvent: Codable {
    let id: String
    let title: String
    let calendarName: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let location: String?
    let notes: String?

    /// Creates a CalendarEvent from an EventKit event.
    /// - Parameter ekEvent: The EventKit event to convert.
    init(from ekEvent: EKEvent) {
        self.id = ekEvent.eventIdentifier ?? UUID().uuidString
        self.title = ekEvent.title ?? ""
        self.calendarName = ekEvent.calendar?.title ?? "Unknown"
        self.startDate = ekEvent.startDate
        self.endDate = ekEvent.endDate
        self.isAllDay = ekEvent.isAllDay
        self.location = ekEvent.location
        self.notes = ekEvent.notes
    }

    /// Formatted time range string (e.g., "10:00 AM - 11:00 AM" or "All day").
    var timeRange: String {
        if isAllDay {
            return "All day"
        }
        return "\(DateFormatters.shortTime.string(from: startDate)) - \(DateFormatters.shortTime.string(from: endDate))"
    }

    /// Full date string for the event's start date.
    var dateString: String {
        DateFormatters.mediumDate.string(from: startDate)
    }

    /// Formats the event for CLI display.
    /// - Parameter showCalendar: Whether to include the calendar name.
    /// - Returns: Formatted string with time, title, location, and optionally calendar.
    func formatted(showCalendar: Bool = false) -> String {
        var result = "- \(timeRange): \(title)"
        if let loc = location, !loc.isEmpty {
            result += " @ \(loc)"
        }
        if showCalendar {
            result += " [\(calendarName)]"
        }
        return result
    }
}
