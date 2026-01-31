import Foundation

/// Protocol defining cache operations for reminder tracking.
///
/// Implementations handle persistent storage of reminder tracking state,
/// allowing reminders to be tracked across sessions.
public protocol CacheServiceProtocol: Sendable {
    /// Loads the cache from disk.
    func loadCache() -> SysmCache

    /// Saves the cache to disk.
    func saveCache(_ cache: SysmCache) throws

    /// Gets all tracked reminder records.
    func getSeenReminders() -> [String: TrackedReminder]

    /// Saves tracked reminder records.
    func saveSeenReminders(_ seen: [String: TrackedReminder]) throws

    /// Tracks a reminder.
    /// - Parameters:
    ///   - name: Reminder name.
    ///   - project: Optional project tag.
    func trackReminder(name: String, project: String?) throws

    /// Dismisses a reminder from tracking.
    /// - Parameter name: Reminder name.
    func dismissReminder(name: String) throws

    /// Marks a tracked reminder as complete.
    /// - Parameter name: Reminder name.
    /// - Returns: True if found and updated.
    func completeTracked(name: String) throws -> Bool

    /// Removes a reminder from tracking entirely.
    /// - Parameter name: Reminder name.
    /// - Returns: True if found and removed.
    func untrackReminder(name: String) throws -> Bool

    /// Gets all currently tracked reminders.
    func getTrackedReminders() -> [(key: String, reminder: TrackedReminder)]

    /// Gets reminders not yet seen (new).
    /// - Parameter currentReminders: Current list of reminders.
    func getNewReminders(currentReminders: [Reminder]) -> [Reminder]
}
