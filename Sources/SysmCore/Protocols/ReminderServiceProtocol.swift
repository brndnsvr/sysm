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
    ///   - dueDate: Optional due date string (parsed by DateParser).
    /// - Returns: The created reminder.
    func addReminder(title: String, listName: String, dueDate: String?) async throws -> Reminder

    /// Marks a reminder as completed.
    /// - Parameter name: Title of the reminder to complete.
    /// - Returns: `true` if the reminder was completed.
    func completeReminder(name: String) async throws -> Bool

    /// Validates and returns reminders that may have issues.
    /// - Returns: Array of reminders with validation concerns.
    func validateReminders() async throws -> [Reminder]
}

extension ReminderServiceProtocol {
    func getReminders(listName: String? = nil, includeCompleted: Bool = false) async throws -> [Reminder] {
        try await getReminders(listName: listName, includeCompleted: includeCompleted)
    }
}
