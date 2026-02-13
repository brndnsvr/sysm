import Foundation

/// Protocol defining cache operations for general-purpose caching and reminder tracking.
///
/// This protocol provides two types of caching:
/// 1. **General-purpose cache**: Service responses with TTL (time-to-live) support
/// 2. **Reminder tracking**: Persistent state tracking for reminders
///
/// The cache is stored in `~/.sysm_cache.json` and supports automatic expiration,
/// invalidation, and size bounds.
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

    // MARK: - General-Purpose Cache

    /// Gets a cached value if it exists and hasn't expired.
    ///
    /// Retrieves a typed value from the cache. Returns `nil` if the key doesn't exist
    /// or if the cached entry has exceeded its TTL.
    ///
    /// - Parameters:
    ///   - key: Cache key in format "{service}:{operation}:{param}".
    ///   - type: The type to decode the cached value as.
    /// - Returns: The cached value if found and not expired, otherwise `nil`.
    /// - Throws: Decoding errors if the cached data doesn't match the expected type.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let cache = CacheService()
    /// if let events: [CalendarEvent] = try? cache.get("calendar:today", as: [CalendarEvent].self) {
    ///     print("Using cached events")
    /// } else {
    ///     let events = try await calendarService.getTodayEvents()
    ///     try cache.set("calendar:today", value: events, ttl: 30)
    /// }
    /// ```
    func get<T: Codable>(_ key: String, as type: T.Type) throws -> T?

    /// Stores a value in the cache with optional TTL.
    ///
    /// Caches a value with a time-to-live. After TTL seconds, the entry expires
    /// and future `get` calls will return `nil`.
    ///
    /// - Parameters:
    ///   - key: Cache key in format "{service}:{operation}:{param}".
    ///   - value: The value to cache (must be Codable).
    ///   - ttl: Time-to-live in seconds. Use 0 for no expiration.
    /// - Throws: Encoding or file system errors.
    ///
    /// ## Recommended TTL Values
    ///
    /// - Calendar queries: 30 seconds
    /// - Contacts search: 300 seconds (5 minutes)
    /// - Photo albums: 60 seconds (1 minute)
    /// - Safari bookmarks: 30 seconds
    ///
    /// ## Example
    ///
    /// ```swift
    /// let cache = CacheService()
    /// let events = try await calendarService.getTodayEvents()
    /// try cache.set("calendar:today", value: events, ttl: 30)
    /// ```
    func set<T: Codable>(_ key: String, value: T, ttl: TimeInterval) throws

    /// Invalidates (removes) a specific cache entry.
    ///
    /// Removes a single entry from the cache by key. Has no effect if key doesn't exist.
    ///
    /// - Parameter key: The cache key to invalidate.
    /// - Throws: File system errors.
    func invalidate(_ key: String) throws

    /// Invalidates all cache entries matching a key prefix.
    ///
    /// Removes all entries whose keys start with the given prefix. Useful for
    /// invalidating all entries for a specific service.
    ///
    /// - Parameter prefix: Key prefix to match (e.g., "calendar:", "contacts:").
    /// - Throws: File system errors.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Invalidate all calendar cache entries
    /// try cache.invalidatePrefix("calendar:")
    /// ```
    func invalidatePrefix(_ prefix: String) throws

    /// Clears all general-purpose cache entries.
    ///
    /// Removes all cached service responses but preserves reminder tracking state.
    /// Use this to reset the cache without losing reminder tracking.
    ///
    /// - Throws: File system errors.
    func clearCache() throws

    /// Removes expired cache entries.
    ///
    /// Scans the cache and removes all entries that have exceeded their TTL.
    /// Called automatically during cache operations but can be invoked manually.
    ///
    /// - Throws: File system errors.
    func cleanupExpired() throws

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
