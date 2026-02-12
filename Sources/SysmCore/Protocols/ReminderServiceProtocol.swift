import Foundation

/// Protocol defining reminder service operations for accessing and managing macOS Reminders.
///
/// Implementations provide access to the user's reminder lists and items through EventKit,
/// supporting queries by list, completion status, and due date.
public protocol ReminderServiceProtocol: Sendable {
    /// Requests access to the user's reminders.
    /// - Returns: `true` if access was granted.
    /// - Throws: If access cannot be determined.
    func requestAccess() async throws -> Bool

    /// Lists all available reminder lists.
    /// - Returns: Array of list names.
    func listNames() async throws -> [String]

    /// Retrieves reminders from the user's lists.
    /// - Parameters:
    ///   - listName: Optional list name to filter by.
    ///   - includeCompleted: Whether to include completed reminders.
    /// - Returns: Array of reminders.
    func getReminders(listName: String?, includeCompleted: Bool) async throws -> [Reminder]

    /// Retrieves reminders due today.
    /// - Returns: Array of today's reminders.
    func getTodayReminders() async throws -> [Reminder]

    /// Creates a new reminder.
    /// - Parameters:
    ///   - title: Reminder title.
    ///   - listName: Name of the list to add to.
    ///   - startDate: Optional start date string (parsed by DateParser).
    ///   - dueDate: Optional due date string (parsed by DateParser).
    ///   - priority: Reminder priority (0=none, 1=high, 5=medium, 9=low).
    ///   - notes: Optional notes for the reminder.
    ///   - url: Optional URL associated with the reminder.
    ///   - recurrence: Optional recurrence rule for repeating reminders.
    ///   - alarms: Optional array of alarms for the reminder.
    /// - Returns: The created reminder.
    func addReminder(title: String, listName: String, startDate: String?, dueDate: String?,
                     priority: Int?, notes: String?, url: String?,
                     recurrence: RecurrenceRule?, alarms: [EventAlarm]?) async throws -> Reminder

    /// Edits an existing reminder.
    /// - Parameters:
    ///   - id: Reminder identifier.
    ///   - newTitle: Optional new title.
    ///   - newStartDate: Optional new start date string.
    ///   - newDueDate: Optional new due date string.
    ///   - newPriority: Optional new priority.
    ///   - newNotes: Optional new notes.
    ///   - newAlarms: Optional new alarms (replaces existing alarms if provided).
    /// - Returns: The updated reminder.
    func editReminder(id: String, newTitle: String?, newStartDate: String?, newDueDate: String?,
                      newPriority: Int?, newNotes: String?, newAlarms: [EventAlarm]?) async throws -> Reminder

    /// Marks a reminder as completed.
    /// - Parameter name: Title of the reminder to complete.
    /// - Returns: `true` if the reminder was completed.
    func completeReminder(name: String) async throws -> Bool

    /// Deletes a reminder.
    /// - Parameter id: Reminder identifier.
    /// - Returns: `true` if the reminder was deleted.
    func deleteReminder(id: String) async throws -> Bool

    /// Moves a reminder to a different list.
    /// - Parameters:
    ///   - id: Reminder identifier.
    ///   - toList: Target list name.
    /// - Returns: The updated reminder.
    func moveReminder(id: String, toList: String) async throws -> Reminder

    /// Creates a new reminder list.
    /// - Parameter name: Name of the list to create.
    /// - Returns: `true` if the list was created.
    func createList(name: String) async throws -> Bool

    /// Deletes a reminder list.
    /// - Parameter name: Name of the list to delete.
    /// - Returns: `true` if the list was deleted.
    func deleteList(name: String) async throws -> Bool

    /// Validates and returns reminders that may have issues.
    /// - Returns: Array of reminders with validation concerns.
    func validateReminders() async throws -> [Reminder]
}

extension ReminderServiceProtocol {
    func getReminders(listName: String? = nil, includeCompleted: Bool = false) async throws -> [Reminder] {
        try await getReminders(listName: listName, includeCompleted: includeCompleted)
    }

    // Backward compatibility
    func addReminder(title: String, listName: String, dueDate: String?) async throws -> Reminder {
        try await addReminder(title: title, listName: listName, startDate: nil, dueDate: dueDate,
                             priority: nil, notes: nil, url: nil, recurrence: nil, alarms: nil)
    }

    func editReminder(id: String, newTitle: String?, newDueDate: String?,
                      newPriority: Int?, newNotes: String?) async throws -> Reminder {
        try await editReminder(id: id, newTitle: newTitle, newStartDate: nil, newDueDate: newDueDate,
                              newPriority: newPriority, newNotes: newNotes, newAlarms: nil)
    }
}
