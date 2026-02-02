import EventKit
import Foundation

public actor ReminderService: ReminderServiceProtocol {
    private let store = EKEventStore()

    public func requestAccess() async throws -> Bool {
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

    public func ensureAccess() async throws {
        let granted = try await requestAccess()
        if !granted {
            throw ReminderError.accessDenied
        }
    }

    public func listNames() async throws -> [String] {
        try await ensureAccess()
        let calendars = store.calendars(for: .reminder)
        return calendars.map { $0.title }
    }

    public func getReminders(listName: String? = nil, includeCompleted: Bool = false) async throws -> [Reminder] {
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

    public func getTodayReminders() async throws -> [Reminder] {
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

    public func addReminder(title: String, listName: String = "Reminders", dueDate: String? = nil,
                            priority: Int? = nil, notes: String? = nil, url: String? = nil,
                            recurrence: RecurrenceRule? = nil) async throws -> Reminder {
        try await ensureAccess()

        guard let calendar = store.calendars(for: .reminder).first(where: { $0.title == listName }) else {
            throw ReminderError.listNotFound(listName)
        }

        let reminder = EKReminder(eventStore: store)
        reminder.title = title
        reminder.calendar = calendar

        if let dueDateStr = dueDate {
            if let parsedDate = Services.dateParser().parse(dueDateStr) {
                let dateComponents = Foundation.Calendar.current.dateComponents(
                    [.year, .month, .day, .hour, .minute],
                    from: parsedDate
                )
                let year = dateComponents.year ?? Foundation.Calendar.current.component(.year, from: Date())
                if year < 2000 || year > 2100 {
                    throw ReminderError.invalidYear(year)
                }
                reminder.dueDateComponents = dateComponents
            } else {
                // Fallback to ISO date parsing
                let dateComponents = try parseDateString(dueDateStr)
                let year = dateComponents.year ?? Foundation.Calendar.current.component(.year, from: Date())
                if year < 2000 || year > 2100 {
                    throw ReminderError.invalidYear(year)
                }
                reminder.dueDateComponents = dateComponents
            }
        }

        if let priority = priority {
            reminder.priority = priority
        }

        if let notes = notes {
            reminder.notes = notes
        }

        if let urlString = url, let reminderUrl = URL(string: urlString) {
            reminder.url = reminderUrl
        }

        if let recurrence = recurrence {
            reminder.addRecurrenceRule(recurrence.toEKRecurrenceRule())
        }

        try store.save(reminder, commit: true)
        return Reminder(from: reminder)
    }

    public func editReminder(id: String, newTitle: String? = nil, newDueDate: String? = nil,
                             newPriority: Int? = nil, newNotes: String? = nil) async throws -> Reminder {
        try await ensureAccess()

        guard let reminder = store.calendarItem(withIdentifier: id) as? EKReminder else {
            throw ReminderError.reminderNotFound(id)
        }

        if let title = newTitle {
            reminder.title = title
        }

        if let dueDateStr = newDueDate {
            if let parsedDate = Services.dateParser().parse(dueDateStr) {
                reminder.dueDateComponents = Foundation.Calendar.current.dateComponents(
                    [.year, .month, .day, .hour, .minute],
                    from: parsedDate
                )
            }
        }

        if let priority = newPriority {
            reminder.priority = priority
        }

        if let notes = newNotes {
            reminder.notes = notes
        }

        try store.save(reminder, commit: true)
        return Reminder(from: reminder)
    }

    public func deleteReminder(id: String) async throws -> Bool {
        try await ensureAccess()

        guard let reminder = store.calendarItem(withIdentifier: id) as? EKReminder else {
            return false
        }

        try store.remove(reminder, commit: true)
        return true
    }

    public func createList(name: String) async throws -> Bool {
        try await ensureAccess()

        // Check if list already exists
        if store.calendars(for: .reminder).contains(where: { $0.title == name }) {
            throw ReminderError.listAlreadyExists(name)
        }

        // Find a source that supports reminder lists
        guard let source = store.sources.first(where: { source in
            source.sourceType == .local || source.sourceType == .calDAV || source.sourceType == .exchange
        }) else {
            throw ReminderError.noValidSource
        }

        let calendar = EKCalendar(for: .reminder, eventStore: store)
        calendar.title = name
        calendar.source = source

        try store.saveCalendar(calendar, commit: true)
        return true
    }

    public func deleteList(name: String) async throws -> Bool {
        try await ensureAccess()

        guard let calendar = store.calendars(for: .reminder).first(where: { $0.title == name }) else {
            throw ReminderError.listNotFound(name)
        }

        try store.removeCalendar(calendar, commit: true)
        return true
    }

    public func completeReminder(name: String) async throws -> Bool {
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

    public func validateReminders() async throws -> [Reminder] {
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
        guard let date = DateFormatters.isoDate.date(from: dateStr) else {
            throw ReminderError.invalidDateFormat(dateStr)
        }

        return Foundation.Calendar.current.dateComponents([.year, .month, .day], from: date)
    }
}

public enum ReminderError: LocalizedError {
    case accessDenied
    case listNotFound(String)
    case listAlreadyExists(String)
    case noValidSource
    case invalidDateFormat(String)
    case invalidYear(Int)
    case reminderNotFound(String)

    public var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Reminders access denied. Grant permission in System Settings > Privacy & Security > Reminders"
        case .listNotFound(let name):
            return "Reminder list '\(name)' not found"
        case .listAlreadyExists(let name):
            return "Reminder list '\(name)' already exists"
        case .noValidSource:
            return "No valid source found for creating reminder lists"
        case .invalidDateFormat(let date):
            return "Invalid date format '\(date)'. Use YYYY-MM-DD or natural language like 'tomorrow 2pm'"
        case .invalidYear(let year):
            return "Year \(year) out of valid range (2000-2100)"
        case .reminderNotFound(let name):
            return "Reminder '\(name)' not found"
        }
    }
}
