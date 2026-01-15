import EventKit
import Foundation

actor ReminderService: ReminderServiceProtocol {
    private let store = EKEventStore()

    func requestAccess() async throws -> Bool {
        if #available(macOS 14.0, *) {
            return try await store.requestFullAccessToReminders()
        } else {
            return try await withCheckedThrowingContinuation { continuation in
                store.requestAccess(to: .reminder) { granted, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: granted)
                    }
                }
            }
        }
    }

    func ensureAccess() async throws {
        let granted = try await requestAccess()
        if !granted {
            throw ReminderError.accessDenied
        }
    }

    func listNames() async throws -> [String] {
        try await ensureAccess()
        let calendars = store.calendars(for: .reminder)
        return calendars.map { $0.title }
    }

    func getReminders(listName: String? = nil, includeCompleted: Bool = false) async throws -> [Reminder] {
        try await ensureAccess()

        let calendars: [EKCalendar]
        if let listName = listName {
            guard let calendar = store.calendars(for: .reminder).first(where: { $0.title == listName }) else {
                throw ReminderError.listNotFound(listName)
            }
            calendars = [calendar]
        } else {
            calendars = store.calendars(for: .reminder)
        }

        let predicate = store.predicateForReminders(in: calendars)

        return try await withCheckedThrowingContinuation { continuation in
            store.fetchReminders(matching: predicate) { ekReminders in
                guard let ekReminders = ekReminders else {
                    continuation.resume(returning: [])
                    return
                }

                let reminders = ekReminders
                    .filter { includeCompleted || !$0.isCompleted }
                    .map { Reminder(from: $0) }

                continuation.resume(returning: reminders)
            }
        }
    }

    func getTodayReminders() async throws -> [Reminder] {
        try await ensureAccess()

        let calendars = store.calendars(for: .reminder)
        let startOfDay = Foundation.Calendar.current.startOfDay(for: Date())
        let endOfDay = Foundation.Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = store.predicateForReminders(in: calendars)

        return try await withCheckedThrowingContinuation { continuation in
            store.fetchReminders(matching: predicate) { ekReminders in
                guard let ekReminders = ekReminders else {
                    continuation.resume(returning: [])
                    return
                }

                let todayReminders = ekReminders.filter { reminder in
                    guard !reminder.isCompleted,
                          let dueDateComponents = reminder.dueDateComponents,
                          let dueDate = Foundation.Calendar.current.date(from: dueDateComponents) else {
                        return false
                    }
                    return dueDate >= startOfDay && dueDate < endOfDay
                }.map { Reminder(from: $0) }

                continuation.resume(returning: todayReminders)
            }
        }
    }

    func addReminder(title: String, listName: String = "Reminders", dueDate: String? = nil) async throws -> Reminder {
        try await ensureAccess()

        guard let calendar = store.calendars(for: .reminder).first(where: { $0.title == listName }) else {
            throw ReminderError.listNotFound(listName)
        }

        let reminder = EKReminder(eventStore: store)
        reminder.title = title
        reminder.calendar = calendar

        if let dueDateStr = dueDate {
            let dateComponents = try parseDateString(dueDateStr)
            let year = dateComponents.year ?? Foundation.Calendar.current.component(.year, from: Date())
            if year < 2000 || year > 2100 {
                throw ReminderError.invalidYear(year)
            }
            reminder.dueDateComponents = dateComponents
        }

        try store.save(reminder, commit: true)
        return Reminder(from: reminder)
    }

    func completeReminder(name: String) async throws -> Bool {
        try await ensureAccess()

        let calendars = store.calendars(for: .reminder)
        let predicate = store.predicateForReminders(in: calendars)
        let eventStore = store

        return try await withCheckedThrowingContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { ekReminders in
                guard let ekReminders = ekReminders else {
                    continuation.resume(returning: false)
                    return
                }

                guard let reminder = ekReminders.first(where: {
                    $0.title == name && !$0.isCompleted
                }) else {
                    continuation.resume(returning: false)
                    return
                }

                reminder.isCompleted = true

                do {
                    try eventStore.save(reminder, commit: true)
                    continuation.resume(returning: true)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func validateReminders() async throws -> [Reminder] {
        try await ensureAccess()

        let calendars = store.calendars(for: .reminder)
        let predicate = store.predicateForReminders(in: calendars)

        return try await withCheckedThrowingContinuation { continuation in
            store.fetchReminders(matching: predicate) { ekReminders in
                guard let ekReminders = ekReminders else {
                    continuation.resume(returning: [])
                    return
                }

                let invalidReminders = ekReminders.compactMap { reminder -> Reminder? in
                    guard let dueDateComponents = reminder.dueDateComponents,
                          let year = dueDateComponents.year else {
                        return nil
                    }
                    if year < 2000 || year > 2100 {
                        return Reminder(from: reminder)
                    }
                    return nil
                }

                continuation.resume(returning: invalidReminders)
            }
        }
    }

    private func parseDateString(_ dateStr: String) throws -> DateComponents {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        guard let date = formatter.date(from: dateStr) else {
            throw ReminderError.invalidDateFormat(dateStr)
        }

        return Foundation.Calendar.current.dateComponents([.year, .month, .day], from: date)
    }
}

enum ReminderError: LocalizedError {
    case accessDenied
    case listNotFound(String)
    case invalidDateFormat(String)
    case invalidYear(Int)
    case reminderNotFound(String)

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Reminders access denied. Grant permission in System Settings > Privacy & Security > Reminders"
        case .listNotFound(let name):
            return "Reminder list '\(name)' not found"
        case .invalidDateFormat(let date):
            return "Invalid date format '\(date)'. Use YYYY-MM-DD"
        case .invalidYear(let year):
            return "Year \(year) out of valid range (2000-2100)"
        case .reminderNotFound(let name):
            return "Reminder '\(name)' not found"
        }
    }
}
