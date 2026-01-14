import Foundation
import EventKit

struct Reminder: Codable {
    let id: String
    let title: String
    let listName: String
    let dueDate: Date?
    let isCompleted: Bool
    let priority: Int
    let notes: String?

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

    var dueDateString: String? {
        guard let date = dueDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var dueDateISO: String? {
        guard let date = dueDate else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.string(from: date)
    }

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
