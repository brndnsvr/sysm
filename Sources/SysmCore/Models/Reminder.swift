import Foundation
import EventKit

/// Reminder priority levels.
public enum ReminderPriority: Int, Codable, CaseIterable {
    case none = 0
    case high = 1
    case medium = 5
    case low = 9

    public var description: String {
        switch self {
        case .none: return "None"
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        }
    }

    public static func from(ekPriority: Int) -> ReminderPriority {
        switch ekPriority {
        case 0: return .none
        case 1...4: return .high
        case 5: return .medium
        case 6...9: return .low
        default: return .none
        }
    }
}

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
    public let priorityLevel: ReminderPriority
    public let notes: String?
    public let url: String?
    public let completionDate: Date?
    public let hasRecurrence: Bool
    public let recurrenceRule: RecurrenceRule?
    public let hasAlarms: Bool

    /// Creates a Reminder from an EventKit reminder.
    /// - Parameter ekReminder: The EventKit reminder to convert.
    public init(from ekReminder: EKReminder) {
        self.id = ekReminder.calendarItemIdentifier
        self.title = ekReminder.title ?? ""
        self.listName = ekReminder.calendar?.title ?? "Unknown"
        self.isCompleted = ekReminder.isCompleted
        self.priority = ekReminder.priority
        self.priorityLevel = ReminderPriority.from(ekPriority: ekReminder.priority)
        self.notes = ekReminder.notes
        self.url = ekReminder.url?.absoluteString
        self.completionDate = ekReminder.completionDate
        self.hasRecurrence = ekReminder.hasRecurrenceRules
        self.hasAlarms = ekReminder.hasAlarms

        if let dueDateComponents = ekReminder.dueDateComponents,
           let date = Foundation.Calendar.current.date(from: dueDateComponents) {
            self.dueDate = date
        } else {
            self.dueDate = nil
        }

        if let rules = ekReminder.recurrenceRules, let firstRule = rules.first {
            self.recurrenceRule = RecurrenceRule(from: firstRule)
        } else {
            self.recurrenceRule = nil
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
    /// - Parameter showDetails: Whether to show additional details.
    /// - Returns: Markdown-style checkbox with title, due date, and optionally list.
    public func formatted(includeList: Bool = false, showDetails: Bool = false) -> String {
        let checkbox = isCompleted ? "[x]" : "[ ]"
        var result = "- \(checkbox) \(title)"

        if priorityLevel != .none {
            result += " !\(priorityLevel.description.lowercased())"
        }

        if let due = dueDateString {
            result += " (due: \(due))"
        }

        if hasRecurrence {
            result += " [repeating]"
        }

        if includeList {
            result += " [\(listName)]"
        }

        if showDetails {
            if let rule = recurrenceRule {
                result += "\n    Recurrence: \(rule.description)"
            }
            if let reminderNotes = notes, !reminderNotes.isEmpty {
                let truncated = reminderNotes.count > 50 ? String(reminderNotes.prefix(50)) + "..." : reminderNotes
                result += "\n    Notes: \(truncated)"
            }
            if let reminderUrl = url {
                result += "\n    URL: \(reminderUrl)"
            }
        }

        return result
    }

    /// Full detailed description for single reminder view.
    public var detailedDescription: String {
        var lines: [String] = []
        let checkbox = isCompleted ? "[x]" : "[ ]"
        lines.append("\(checkbox) \(title)")
        lines.append("List: \(listName)")

        if priorityLevel != .none {
            lines.append("Priority: \(priorityLevel.description)")
        }

        if let due = dueDateString {
            lines.append("Due: \(due)")
        }

        if let rule = recurrenceRule {
            lines.append("Repeats: \(rule.description)")
        }

        if isCompleted, let completed = completionDate {
            lines.append("Completed: \(DateFormatters.fullDateTime.string(from: completed))")
        }

        if let reminderUrl = url {
            lines.append("URL: \(reminderUrl)")
        }

        if let reminderNotes = notes, !reminderNotes.isEmpty {
            lines.append("Notes: \(reminderNotes)")
        }

        return lines.joined(separator: "\n")
    }
}
