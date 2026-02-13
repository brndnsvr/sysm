import Foundation

/// Protocol defining cache operations for reminder tracking state.
///
/// This protocol handles persistent storage of reminder tracking state in a JSON cache file
/// (`~/.sysm-cache.json`). Tracks which reminders have been seen, their completion status,
/// and associated project tags for context-aware reminder management.
///
/// ## Cache Storage
///
/// The cache file stores:
/// - Seen reminders with first-seen timestamps
/// - Tracked reminders with project associations
/// - Completion status and timestamps
///
/// ## Usage Example
///
/// ```swift
/// let cache = CacheService()
///
/// // Track a new reminder
/// try cache.trackReminder(name: "Review PR #123", project: "Development")
///
/// // Get all tracked reminders
/// let tracked = cache.getTrackedReminders()
/// for (name, reminder) in tracked {
///     print("\(name): \(reminder.project ?? "no project")")
/// }
///
/// // Mark as complete
/// let found = try cache.completeTracked(name: "Review PR #123")
/// if found {
///     print("Marked complete")
/// }
///
/// // Untrack when done
/// try cache.untrackReminder(name: "Review PR #123")
/// ```
///
/// ## Thread Safety
///
/// Implementations are marked as `Sendable` and safe to use across actor boundaries.
/// File I/O operations are synchronous.
///
/// ## Error Handling
///
/// Methods can throw standard file system errors:
/// - File write errors
/// - JSON encoding/decoding errors
/// - Permission errors
///
public protocol CacheServiceProtocol: Sendable {
    // MARK: - Cache File Operations

    /// Loads the cache from disk.
    ///
    /// Reads and parses the cache JSON file. Returns empty cache if file doesn't exist.
    ///
    /// - Returns: ``SysmCache`` object with all cached data.
    func loadCache() -> SysmCache

    /// Saves the cache to disk.
    ///
    /// Writes the cache object to the JSON file, creating it if necessary.
    ///
    /// - Parameter cache: The cache object to save.
    /// - Throws: File system or JSON encoding errors.
    func saveCache(_ cache: SysmCache) throws

    // MARK: - Seen Reminders

    /// Gets all tracked reminder records.
    ///
    /// Returns the internal seen reminders dictionary for advanced use cases.
    ///
    /// - Returns: Dictionary mapping reminder names to ``TrackedReminder`` objects.
    func getSeenReminders() -> [String: TrackedReminder]

    /// Saves tracked reminder records.
    ///
    /// Updates the seen reminders cache and persists to disk.
    ///
    /// - Parameter seen: Dictionary of reminder names to tracked reminder data.
    /// - Throws: File system or JSON encoding errors.
    func saveSeenReminders(_ seen: [String: TrackedReminder]) throws

    // MARK: - Reminder Tracking

    /// Tracks a reminder for follow-up.
    ///
    /// Adds a reminder to the tracked set, optionally associating it with a project tag.
    /// Tracked reminders persist across sessions until explicitly untracked or completed.
    ///
    /// - Parameters:
    ///   - name: Reminder title/name.
    ///   - project: Optional project tag for categorization.
    /// - Throws: File system or JSON encoding errors.
    ///
    /// ## Example
    ///
    /// ```swift
    /// try cache.trackReminder(name: "Deploy v2.0", project: "Release")
    /// try cache.trackReminder(name: "Buy milk", project: nil)
    /// ```
    func trackReminder(name: String, project: String?) throws

    /// Dismisses a reminder from tracking.
    ///
    /// Removes a reminder from the tracked set without marking it as complete.
    /// Use this to stop tracking a reminder that's no longer relevant.
    ///
    /// - Parameter name: Reminder title/name to dismiss.
    /// - Throws: File system or JSON encoding errors.
    func dismissReminder(name: String) throws

    /// Marks a tracked reminder as complete.
    ///
    /// Updates the tracked reminder's status to completed. The reminder remains in the
    /// tracking set but is marked as done.
    ///
    /// - Parameter name: Reminder title/name to mark complete.
    /// - Returns: `true` if reminder was found and updated, `false` if not tracked.
    /// - Throws: File system or JSON encoding errors.
    ///
    /// ## Example
    ///
    /// ```swift
    /// if try cache.completeTracked(name: "Deploy v2.0") {
    ///     print("Marked as complete")
    /// } else {
    ///     print("Reminder not tracked")
    /// }
    /// ```
    func completeTracked(name: String) throws -> Bool

    /// Removes a reminder from tracking entirely.
    ///
    /// Completely removes a reminder from the tracking set. Different from dismiss
    /// as it removes all trace of tracking.
    ///
    /// - Parameter name: Reminder title/name to untrack.
    /// - Returns: `true` if reminder was found and removed, `false` if not tracked.
    /// - Throws: File system or JSON encoding errors.
    func untrackReminder(name: String) throws -> Bool

    /// Gets all currently tracked reminders.
    ///
    /// Returns all reminders in the tracking set with their metadata.
    ///
    /// - Returns: Array of tuples containing reminder name and ``TrackedReminder`` data.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let tracked = cache.getTrackedReminders()
    /// print("Tracking \(tracked.count) reminders:")
    /// for (name, reminder) in tracked {
    ///     let status = reminder.completed ? "✓" : "○"
    ///     let project = reminder.project ?? "no project"
    ///     print("  \(status) \(name) (\(project))")
    /// }
    /// ```
    func getTrackedReminders() -> [(key: String, reminder: TrackedReminder)]

    // MARK: - New Reminders Detection

    /// Gets reminders not yet seen (new reminders).
    ///
    /// Compares the current reminders list against the cache to find reminders that
    /// haven't been seen before. Useful for detecting new reminders added since last check.
    ///
    /// - Parameter currentReminders: Current list of reminders from the system.
    /// - Returns: Array of new ``Reminder`` objects not in the cache.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let allReminders = try reminderService.getReminders()
    /// let newOnes = cache.getNewReminders(currentReminders: allReminders)
    /// if !newOnes.isEmpty {
    ///     print("Found \(newOnes.count) new reminders:")
    ///     for reminder in newOnes {
    ///         print("  - \(reminder.title)")
    ///     }
    /// }
    /// ```
    func getNewReminders(currentReminders: [Reminder]) -> [Reminder]
}
