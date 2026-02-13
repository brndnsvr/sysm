import Foundation

/// Protocol defining reminder service operations for accessing and managing macOS Reminders.
///
/// This protocol provides comprehensive access to the user's reminder lists and items through EventKit,
/// supporting queries by list, completion status, due date, and full CRUD operations. Reminders in macOS
/// support priorities, alarms, recurrence, locations, and rich metadata.
///
/// ## Permission Requirements
///
/// Before using any reminder operations, the app must request and obtain Reminders access:
/// - System Settings > Privacy & Security > Reminders
/// - Use ``requestAccess()`` to prompt the user for permission
///
/// ## Usage Example
///
/// ```swift
/// let service = ReminderService()
///
/// // Request access first
/// try await service.requestAccess()
///
/// // Get today's reminders
/// let todayReminders = try await service.getTodayReminders()
/// for reminder in todayReminders {
///     print("\(reminder.title) - Priority: \(reminder.priority)")
/// }
///
/// // Create a new reminder with due date
/// let reminder = try await service.addReminder(
///     title: "Review pull requests",
///     listName: "Work",
///     startDate: nil,
///     dueDate: "tomorrow 2pm",
///     priority: 5, // Medium priority
///     notes: "Check team submissions",
///     url: nil,
///     recurrence: nil,
///     alarms: nil
/// )
///
/// // Complete a reminder
/// try await service.completeReminder(name: "Review pull requests")
/// ```
///
/// ## Thread Safety
///
/// Implementations are marked as `Sendable` and safe to use across actor boundaries.
/// EventKit operations are performed on the main actor internally.
///
/// ## Error Handling
///
/// All methods can throw ``ReminderError`` variants:
/// - ``ReminderError/accessDenied`` - Reminders permission not granted
/// - ``ReminderError/listNotFound(_:)`` - Specified list doesn't exist
/// - ``ReminderError/listAlreadyExists(_:)`` - List name already in use
/// - ``ReminderError/noValidSource`` - No valid source for creating lists (Reminders app not initialized)
/// - ``ReminderError/invalidDateFormat(_:)`` - Date string parsing failed
/// - ``ReminderError/invalidYear(_:)`` - Year outside valid range (2000-2100)
/// - ``ReminderError/reminderNotFound(_:)`` - Reminder not found by name or ID
///
public protocol ReminderServiceProtocol: Sendable {
    // MARK: - Access Management

    /// Requests access to the user's reminders data.
    ///
    /// This method must be called before any other reminder operations. It will prompt
    /// the user for permission if not already granted. Subsequent calls return the
    /// cached permission status.
    ///
    /// - Returns: `true` if access was granted, `false` if denied.
    /// - Throws: ``ReminderError/accessDenied`` if permission is denied or restricted.
    ///
    /// ## Example
    ///
    /// ```swift
    /// do {
    ///     let granted = try await service.requestAccess()
    ///     if granted {
    ///         print("Reminders access granted")
    ///     }
    /// } catch ReminderError.accessDenied {
    ///     print("User denied reminders access")
    /// }
    /// ```
    func requestAccess() async throws -> Bool

    // MARK: - List Management

    /// Lists all available reminder lists by name.
    ///
    /// Returns list names in the order they appear in the Reminders app.
    /// Includes both local and synced (iCloud) lists.
    ///
    /// - Returns: Array of list names.
    /// - Throws: ``ReminderError/accessDenied`` if reminders access not granted.
    func listNames() async throws -> [String]

    /// Creates a new reminder list.
    ///
    /// - Parameter name: Name of the list to create (must be unique).
    /// - Returns: `true` if the list was created successfully.
    /// - Throws:
    ///   - ``ReminderError/accessDenied`` if reminders access not granted.
    ///   - ``ReminderError/listAlreadyExists(_:)`` if a list with that name already exists.
    ///   - ``ReminderError/noValidSource`` if no valid source is available (Reminders app not initialized).
    func createList(name: String) async throws -> Bool

    /// Deletes a reminder list and all its reminders.
    ///
    /// **Warning:** This permanently deletes the list and all reminders it contains.
    ///
    /// - Parameter name: Name of the list to delete.
    /// - Returns: `true` if the list was deleted.
    /// - Throws:
    ///   - ``ReminderError/accessDenied`` if reminders access not granted.
    ///   - ``ReminderError/listNotFound(_:)`` if the list doesn't exist.
    func deleteList(name: String) async throws -> Bool

    // MARK: - Reminder Queries

    /// Retrieves reminders from the user's lists with optional filtering.
    ///
    /// - Parameters:
    ///   - listName: Optional list name to filter by. If `nil`, searches all lists.
    ///   - includeCompleted: Whether to include completed reminders. Default is `false`.
    /// - Returns: Array of ``Reminder`` objects matching the criteria.
    /// - Throws:
    ///   - ``ReminderError/accessDenied`` if reminders access not granted.
    ///   - ``ReminderError/listNotFound(_:)`` if specified list doesn't exist.
    func getReminders(listName: String?, includeCompleted: Bool) async throws -> [Reminder]

    /// Retrieves all reminders due today.
    ///
    /// Returns reminders with due dates from midnight to 11:59 PM today (local time).
    /// Only includes incomplete reminders.
    ///
    /// - Returns: Array of today's ``Reminder`` objects.
    /// - Throws: ``ReminderError/accessDenied`` if reminders access not granted.
    func getTodayReminders() async throws -> [Reminder]

    // MARK: - Reminder CRUD Operations

    /// Creates a new reminder with comprehensive options.
    ///
    /// Creates a reminder with support for priorities, alarms, recurrence, and metadata.
    /// Date strings are parsed using natural language (e.g., "tomorrow 2pm", "next Monday").
    ///
    /// - Parameters:
    ///   - title: Reminder title (required).
    ///   - listName: Name of the list to add to (must exist).
    ///   - startDate: Optional start date string (parsed by ``DateParser``).
    ///   - dueDate: Optional due date string (parsed by ``DateParser``).
    ///   - priority: Priority level: 0=none, 1=high, 5=medium, 9=low. Default is 0.
    ///   - notes: Optional notes/description.
    ///   - url: Optional URL associated with the reminder.
    ///   - recurrence: Optional ``RecurrenceRule`` for repeating reminders.
    ///   - alarms: Optional array of ``EventAlarm`` objects for notifications.
    /// - Returns: The created ``Reminder`` with ID assigned.
    /// - Throws:
    ///   - ``ReminderError/accessDenied`` if reminders access not granted.
    ///   - ``ReminderError/listNotFound(_:)`` if specified list doesn't exist.
    ///   - ``ReminderError/invalidDateFormat(_:)`` if date string parsing fails.
    func addReminder(title: String, listName: String, startDate: String?, dueDate: String?,
                     priority: Int?, notes: String?, url: String?,
                     recurrence: RecurrenceRule?, alarms: [EventAlarm]?) async throws -> Reminder

    /// Updates an existing reminder's properties.
    ///
    /// Only non-nil parameters are updated. All date strings are parsed using natural language.
    ///
    /// - Parameters:
    ///   - id: Reminder identifier.
    ///   - newTitle: Optional new title.
    ///   - newStartDate: Optional new start date string.
    ///   - newDueDate: Optional new due date string.
    ///   - newPriority: Optional new priority (0, 1, 5, or 9).
    ///   - newNotes: Optional new notes.
    ///   - newAlarms: Optional new alarms (replaces all existing alarms if provided).
    /// - Returns: The updated ``Reminder``.
    /// - Throws:
    ///   - ``ReminderError/accessDenied`` if reminders access not granted.
    ///   - ``ReminderError/reminderNotFound(_:)`` if reminder doesn't exist.
    ///   - ``ReminderError/invalidDateFormat(_:)`` if date string parsing fails.
    func editReminder(id: String, newTitle: String?, newStartDate: String?, newDueDate: String?,
                      newPriority: Int?, newNotes: String?, newAlarms: [EventAlarm]?) async throws -> Reminder

    /// Marks a reminder as completed.
    ///
    /// Finds the first incomplete reminder with the specified title and marks it complete.
    ///
    /// - Parameter name: Title of the reminder to complete (exact match).
    /// - Returns: `true` if the reminder was completed.
    /// - Throws:
    ///   - ``ReminderError/accessDenied`` if reminders access not granted.
    ///   - ``ReminderError/reminderNotFound(_:)`` if no incomplete reminder with that title exists.
    func completeReminder(name: String) async throws -> Bool

    /// Deletes a reminder permanently.
    ///
    /// - Parameter id: Reminder identifier.
    /// - Returns: `true` if the reminder was deleted.
    /// - Throws:
    ///   - ``ReminderError/accessDenied`` if reminders access not granted.
    ///   - ``ReminderError/reminderNotFound(_:)`` if reminder doesn't exist.
    func deleteReminder(id: String) async throws -> Bool

    /// Moves a reminder to a different list.
    ///
    /// Transfers the reminder to another list while preserving all its properties.
    ///
    /// - Parameters:
    ///   - id: Reminder identifier.
    ///   - toList: Target list name (must exist).
    /// - Returns: The updated ``Reminder`` in its new list.
    /// - Throws:
    ///   - ``ReminderError/accessDenied`` if reminders access not granted.
    ///   - ``ReminderError/reminderNotFound(_:)`` if reminder doesn't exist.
    ///   - ``ReminderError/listNotFound(_:)`` if target list doesn't exist.
    func moveReminder(id: String, toList: String) async throws -> Reminder

    // MARK: - Validation

    /// Validates all reminders and returns those with potential issues.
    ///
    /// Checks for reminders with:
    /// - Invalid date ranges (start after due)
    /// - Missing required fields
    /// - Malformed data
    ///
    /// - Returns: Array of ``Reminder`` objects that may have issues.
    /// - Throws: ``ReminderError/accessDenied`` if reminders access not granted.
    func validateReminders() async throws -> [Reminder]
}

// MARK: - Default Implementations

/// Default implementations for simplified reminder creation.
extension ReminderServiceProtocol {
    /// Retrieves reminders with default parameters.
    ///
    /// Convenience method that defaults to all lists and excludes completed reminders.
    ///
    /// - Parameters:
    ///   - listName: Optional list name. Default is `nil` (all lists).
    ///   - includeCompleted: Whether to include completed. Default is `false`.
    /// - Returns: Array of incomplete ``Reminder`` objects.
    public func getReminders(listName: String? = nil, includeCompleted: Bool = false) async throws -> [Reminder] {
        try await getReminders(listName: listName, includeCompleted: includeCompleted)
    }

    /// Creates a basic reminder with minimal parameters.
    ///
    /// Convenience method for creating simple reminders without advanced features.
    /// Sets default priority and no recurrence or alarms.
    ///
    /// - Parameters:
    ///   - title: Reminder title.
    ///   - listName: List to add to.
    ///   - dueDate: Optional due date string (e.g., "tomorrow", "Friday 3pm").
    /// - Returns: The created ``Reminder``.
    public func addReminder(title: String, listName: String, dueDate: String?) async throws -> Reminder {
        try await addReminder(title: title, listName: listName, startDate: nil, dueDate: dueDate,
                             priority: nil, notes: nil, url: nil, recurrence: nil, alarms: nil)
    }

    /// Updates a reminder with simplified parameters.
    ///
    /// Convenience method for basic updates without modifying alarms or start date.
    ///
    /// - Parameters:
    ///   - id: Reminder identifier.
    ///   - newTitle: Optional new title.
    ///   - newDueDate: Optional new due date string.
    ///   - newPriority: Optional new priority.
    ///   - newNotes: Optional new notes.
    /// - Returns: The updated ``Reminder``.
    public func editReminder(id: String, newTitle: String?, newDueDate: String?,
                      newPriority: Int?, newNotes: String?) async throws -> Reminder {
        try await editReminder(id: id, newTitle: newTitle, newStartDate: nil, newDueDate: newDueDate,
                              newPriority: newPriority, newNotes: newNotes, newAlarms: nil)
    }
}
