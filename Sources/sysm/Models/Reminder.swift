import Foundation
import EventKit

/// Represents a reminder from macOS Reminders.
///
/// This model wraps EventKit's `EKReminder` for JSON serialization and
/// provides convenient formatting methods for CLI output.
struct Reminder: Codable {
    let id: String
    let title: String
    let listName: String
    let dueDate: Date?
    let isCompleted: Bool
    let priority: Int
    let notes: String?

    /// Creates a Reminder from an EventKit reminder.
    /// - Parameter ekReminder: The EventKit reminder to convert.
    init(from ekReminder: EKReminder) {
        self.id = ekReminder.calendarItemIdentifier
        self.title = ekReminder.title ?? ""
        self.listName = ekReminder.calendar?.title ?? "Unknown"
        self.isCompleted = ekReminder.isCompleted
        self.priority = ekReminder.priority
        self.notes = ekReminder.notes

        if let dueDateComponents = ekReminder.dueDateComponents,
           let date = Foundation.Calendar.current.date(from: dueDateComponents) {
            self.dueDate = date
        } else {
            self.dueDate = nil
        }
    }

    /// Human-readable due date string.
    var dueDateString: String? {
        guard let date = dueDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    /// ISO 8601 formatted due date string.
    var dueDateISO: String? {
        guard let date = dueDate else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.string(from: date)
    }

    /// Formats the reminder for CLI display.
    /// - Parameter includeList: Whether to include the list name.
    /// - Returns: Markdown-style checkbox with title, due date, and optionally list.
    func formatted(includeList: Bool = false) -> String {
        var result = "- [ ] \(title)"
        if let due = dueDateString {
            result += " (due: \(due))"
        }
        if includeList {
            result += " [\(listName)]"
        }
        return result
    }
}
