import Foundation
import EventKit

/// Represents a reminder from macOS Reminders.
///
/// This model wraps EventKit's `EKReminder` for JSON serialization and
/// provides convenient formatting methods for CLI output.
public struct Reminder: Codable {
    public let id: String
    public let title: String
    public let listName: String
    public let dueDate: Date?
    public let isCompleted: Bool
    public let priority: Int
    public let notes: String?

    /// Creates a Reminder from an EventKit reminder.
    /// - Parameter ekReminder: The EventKit reminder to convert.
    public init(from ekReminder: EKReminder) {
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
    public var dueDateString: String? {
        guard let date = dueDate else { return nil }
        return DateFormatters.fullDateTime.string(from: date)
    }

    /// ISO 8601 formatted due date string.
    public var dueDateISO: String? {
        guard let date = dueDate else { return nil }
        return DateFormatters.iso8601DateOnly.string(from: date)
    }

    /// Formats the reminder for CLI display.
    /// - Parameter includeList: Whether to include the list name.
    /// - Returns: Markdown-style checkbox with title, due date, and optionally list.
    public func formatted(includeList: Bool = false) -> String {
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
