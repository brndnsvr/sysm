import EventKit
import Foundation

struct CalendarEvent: Codable {
    let id: String
    let title: String
    let calendarName: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let location: String?
    let notes: String?

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

    var timeRange: String {
        let formatter = DateFormatter()
        if isAllDay {
            return "All day"
        }
        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }

    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: startDate)
    }

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
