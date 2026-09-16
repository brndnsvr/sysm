import EventKit
import Foundation

public actor ReminderService: ReminderServiceProtocol {
    private let store = EKEventStore()

    public func requestAccess() async throws -> Bool {
        return try await store.requestFullAccessToReminders()
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
                    continuation.resume(throwing: ReminderError.fetchFailed)
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
                    continuation.resume(throwing: ReminderError.fetchFailed)
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

    public func addReminder(title: String, listName: String = "Reminders", startDate: String? = nil, dueDate: String? = nil,
                            priority: Int? = nil, notes: String? = nil, url: String? = nil,
                            recurrence: RecurrenceRule? = nil, alarms: [EventAlarm]? = nil) async throws -> Reminder {
        try await ensureAccess()

        guard let calendar = store.calendars(for: .reminder).first(where: { $0.title == listName }) else {
            throw ReminderError.listNotFound(listName)
        }

        let reminder = EKReminder(eventStore: store)
        reminder.title = title
        reminder.calendar = calendar

        if let startDateStr = startDate {
            reminder.startDateComponents = try Self.dateComponents(for: startDateStr, parser: Services.dateParser())
        }

        if let dueDateStr = dueDate {
            reminder.dueDateComponents = try Self.dateComponents(for: dueDateStr, parser: Services.dateParser())
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

        if let alarms = alarms {
            for alarm in alarms {
                reminder.addAlarm(alarm.toEKAlarm())
            }
        }

        try store.save(reminder, commit: true)
        return Reminder(from: reminder)
    }

    /// Date components for a start or due date the user typed.
    ///
    /// EventKit treats components without an hour and minute as all-day
    /// (EKReminder.h). Always including them made "2026-01-15", "friday",
    /// and "tomorrow" due at 12:00 AM, with alarms firing at midnight.
    /// Unparseable input throws; edit used to skip it silently.
    static func dateComponents(for input: String, parser: any DateParserProtocol) throws -> DateComponents {
        guard let date = parser.parse(input) else {
            throw ReminderError.invalidDateFormat(input)
        }

        let fields: Set<Foundation.Calendar.Component> = parser.includesTime(input)
            ? [.year, .month, .day, .hour, .minute]
            : [.year, .month, .day]
        let components = Foundation.Calendar.current.dateComponents(fields, from: date)

        let year = components.year ?? Foundation.Calendar.current.component(.year, from: date)
        guard (2000...2100).contains(year) else {
            throw ReminderError.invalidYear(year)
        }
        return components
    }

    public func editReminder(id: String, newTitle: String? = nil, newStartDate: String? = nil, newDueDate: String? = nil,
                             newPriority: Int? = nil, newNotes: String? = nil, newAlarms: [EventAlarm]? = nil) async throws -> Reminder {
        try await ensureAccess()

        guard let reminder = store.calendarItem(withIdentifier: id) as? EKReminder else {
            throw ReminderError.reminderNotFound(id)
        }

        if let title = newTitle {
            reminder.title = title
        }

        if let startDateStr = newStartDate {
            reminder.startDateComponents = try Self.dateComponents(for: startDateStr, parser: Services.dateParser())
        }

        if let dueDateStr = newDueDate {
            reminder.dueDateComponents = try Self.dateComponents(for: dueDateStr, parser: Services.dateParser())
        }

        if let priority = newPriority {
            reminder.priority = priority
        }

        if let notes = newNotes {
            reminder.notes = notes
        }

        if let newAlarms = newAlarms {
            // Remove existing alarms
            if let existingAlarms = reminder.alarms {
                for alarm in existingAlarms {
                    reminder.removeAlarm(alarm)
                }
            }
            // Add new alarms
            for alarm in newAlarms {
                reminder.addAlarm(alarm.toEKAlarm())
            }
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

    public func moveReminder(id: String, toList: String) async throws -> Reminder {
        try await ensureAccess()

        guard let reminder = store.calendarItem(withIdentifier: id) as? EKReminder else {
            throw ReminderError.reminderNotFound(id)
        }

        guard let newCalendar = store.calendars(for: .reminder).first(where: { $0.title == toList }) else {
            throw ReminderError.listNotFound(toList)
        }

        reminder.calendar = newCalendar
        try store.save(reminder, commit: true)
        return Reminder(from: reminder)
    }

    /// The account a new reminder list belongs to: where the store already
    /// files new reminders, else one that holds lists, else iCloud.
    private func reminderSource() -> EKSource? {
        Self.preferredReminderSource(
            store.sources,
            default: store.defaultCalendarForNewReminders()?.source,
            holdsLists: { !$0.calendars(for: .reminder).isEmpty },
            title: { $0.title },
            type: { $0.sourceType }
        )
    }

    /// The account a new reminder list belongs to.
    ///
    /// A Mac can carry two CalDAV accounts both titled "iCloud", one holding
    /// the calendars and the other the reminder lists. Choosing on the title
    /// alone took whichever came first, and saving a list to the calendar one
    /// failed with "That account does not support reminders". An account the
    /// store already keeps lists in demonstrably accepts them, so ask where
    /// new reminders go first, then prefer an account that holds lists, and
    /// keep the old title and type order only as a last resort.
    static func preferredReminderSource<Source>(
        _ sources: [Source],
        default defaultSource: Source?,
        holdsLists: (Source) -> Bool,
        title: (Source) -> String,
        type: (Source) -> EKSourceType
    ) -> Source? {
        if let defaultSource { return defaultSource }

        let hosting = sources.filter(holdsLists)
        if let icloud = hosting.first(where: { title($0).lowercased().contains("icloud") }) { return icloud }
        if let hosting = hosting.first { return hosting }

        if let icloud = sources.first(where: {
            type($0) == .calDAV && title($0).lowercased().contains("icloud")
        }) { return icloud }
        return sources.first(where: { type($0) == .calDAV })
            ?? sources.first(where: { type($0) == .local })
    }

    public func createList(name: String) async throws -> Bool {
        try await ensureAccess()

        // Check if list already exists
        if store.calendars(for: .reminder).contains(where: { $0.title == name }) {
            throw ReminderError.listAlreadyExists(name)
        }

        guard let source = reminderSource() else {
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

    public func completeReminder(_ selector: ReminderSelector) async throws -> Reminder {
        try await ensureAccess()

        let reminder = try await resolveReminder(selector)
        reminder.isCompleted = true
        try store.save(reminder, commit: true)
        return Reminder(from: reminder)
    }

    /// Finds the one reminder a selector names.
    ///
    /// Completion used to take the first incomplete reminder with the title in
    /// any list, and marked and saved it inside EventKit's fetch callback, off
    /// this actor. The callback now only reports identifiers, a title shared by
    /// several incomplete reminders is refused, and the change happens here.
    private func resolveReminder(_ selector: ReminderSelector) async throws -> EKReminder {
        let identifier: String
        switch selector {
        case .id(let id):
            identifier = id
        case .title(let title):
            let predicate = store.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: nil)
            let matches: [(id: String, list: String)] = try await withCheckedThrowingContinuation { continuation in
                store.fetchReminders(matching: predicate) { ekReminders in
                    guard let ekReminders else {
                        continuation.resume(throwing: ReminderError.fetchFailed)
                        return
                    }
                    continuation.resume(returning: ekReminders
                        .filter { $0.title == title }
                        .map { (id: $0.calendarItemIdentifier, list: $0.calendar?.title ?? "Unknown") })
                }
            }
            guard let first = matches.first else {
                throw ReminderError.reminderNotFound(title)
            }
            guard matches.count == 1 else {
                throw ReminderError.ambiguousReminder(title, matches.map { "\($0.id)  (\($0.list))" })
            }
            identifier = first.id
        }

        guard let reminder = store.calendarItem(withIdentifier: identifier) as? EKReminder else {
            throw ReminderError.reminderNotFound(selector.description)
        }
        return reminder
    }

    public func validateReminders() async throws -> [Reminder] {
        try await ensureAccess()

        let calendars = store.calendars(for: .reminder)
        let predicate = store.predicateForReminders(in: calendars)

        return try await withCheckedThrowingContinuation { continuation in
            store.fetchReminders(matching: predicate) { ekReminders in
                guard let ekReminders = ekReminders else {
                    continuation.resume(throwing: ReminderError.fetchFailed)
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
}

/// Picks the reminder an operation acts on.
public enum ReminderSelector: Sendable, CustomStringConvertible {
    /// A reminder's calendar item identifier, as shown in `--json` output.
    case id(String)
    /// The exact title of an incomplete reminder.
    case title(String)

    public var description: String {
        switch self {
        case .id(let id): return id
        case .title(let title): return title
        }
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
    case fetchFailed
    case ambiguousReminder(String, [String])

    public var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Reminders access denied"
        case .listNotFound(let name):
            return "Reminder list '\(name)' not found"
        case .listAlreadyExists(let name):
            return "Reminder list '\(name)' already exists"
        case .noValidSource:
            return "No valid source found for creating reminder lists"
        case .invalidDateFormat(let date):
            return "Invalid date format: '\(date)'"
        case .invalidYear(let year):
            return "Year \(year) out of valid range (2000-2100)"
        case .reminderNotFound(let name):
            return "Reminder '\(name)' not found"
        case .fetchFailed:
            return "Failed to fetch reminders"
        case .ambiguousReminder(let title, let candidates):
            return "\(candidates.count) incomplete reminders are titled '\(title)'; choose one with --id:\n  "
                + candidates.joined(separator: "\n  ")
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .ambiguousReminder:
            return "Pass the reminder's ID with --id instead of its title."
        case .accessDenied:
            return """
            Grant reminders access in System Settings:
            1. Open System Settings
            2. Navigate to Privacy & Security > Reminders
            3. Enable access for Terminal (or your terminal app)
            4. Restart sysm

            Quick: open "x-apple.systempreferences:com.apple.preference.security?Privacy_Reminders"
            """
        case .listNotFound(let name):
            return """
            The list '\(name)' doesn't exist.

            Try:
            - List available lists: sysm reminders lists
            - Create the list: sysm reminders create-list "\(name)"
            - Use default list (omit --list flag)
            """
        case .listAlreadyExists(let name):
            return """
            A list named '\(name)' already exists.

            Try:
            - Use a different name
            - List existing lists: sysm reminders lists
            """
        case .noValidSource:
            return """
            Cannot create reminder lists because no account accepts them.

            This usually means:
            - iCloud Reminders is not enabled
            - Reminders app hasn't been opened yet

            Try:
            1. Open System Settings > Apple Account > iCloud and enable Reminders
            2. Open Reminders app and wait for it to sync
            3. Try the command again
            """
        case .invalidDateFormat(let date):
            return """
            Invalid date format: '\(date)'

            Supported formats:
            - "tomorrow 2pm"
            - "2024-12-25 14:00"
            - "next monday 9am"
            - "friday"
            """
        case .invalidYear:
            return "Use a year between 2000 and 2100"
        case .reminderNotFound(let name):
            return """
            Reminder '\(name)' not found.

            Try:
            - List reminders: sysm reminders list
            - Include completed: sysm reminders list --all
            - Use reminder ID instead of name
            """
        case .fetchFailed:
            return """
            The reminders fetch returned no data. This may indicate:
            - Reminders access was revoked during the request
            - The EventKit store encountered an internal error

            Try:
            - Check reminders access in System Settings > Privacy & Security > Reminders
            - Restart sysm and try again
            """
        }
    }
}
