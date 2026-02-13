import Foundation

/// Protocol defining trigger file synchronization operations for external tool integration.
///
/// This protocol handles syncing tracked reminders to a markdown trigger file that can be
/// monitored by external automation tools. Enables integration with tools like Hazel, Keyboard
/// Maestro, or custom scripts that watch for file changes.
///
/// ## Trigger File
///
/// The trigger file (`~/.sysm-triggers.md`) contains:
/// - List of tracked reminders in markdown format
/// - Project tags and completion status
/// - Timestamps for tracking
/// - Machine-readable format for parsing
///
/// ## Usage Example
///
/// ```swift
/// let trigger = TriggerService()
/// let cache = CacheService()
///
/// // Get tracked reminders from cache
/// let tracked = cache.getTrackedReminders()
///
/// // Sync to trigger file
/// try trigger.syncTrackedReminders(tracked)
/// print("Synced \(tracked.count) reminders to trigger file")
/// ```
///
/// ## Integration Use Cases
///
/// - **Hazel**: Watch trigger file for changes, trigger actions based on reminder content
/// - **Keyboard Maestro**: Parse trigger file to display reminder dashboard
/// - **Custom Scripts**: Monitor file modification time, parse and process reminders
/// - **Task Managers**: Import tracked reminders into external systems
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
/// - Permission errors
/// - Directory creation errors
///
public protocol TriggerServiceProtocol: Sendable {
    // MARK: - Synchronization

    /// Syncs tracked reminders to the trigger file.
    ///
    /// Writes all tracked reminders to the markdown trigger file in a structured format.
    /// The file is completely rewritten on each sync to ensure accuracy.
    ///
    /// - Parameter tracked: Array of tuples containing reminder names and their ``TrackedReminder`` data.
    /// - Throws: File system errors if unable to write trigger file.
    ///
    /// ## File Format
    ///
    /// The trigger file uses markdown format:
    /// ```markdown
    /// # Tracked Reminders
    /// Last synced: 2024-01-15 14:30:00
    ///
    /// ## Work
    /// - [ ] Deploy v2.0
    /// - [x] Review PR #123
    ///
    /// ## Personal
    /// - [ ] Buy groceries
    /// ```
    ///
    /// ## Example
    ///
    /// ```swift
    /// let cache = CacheService()
    /// let trigger = TriggerService()
    ///
    /// let tracked = cache.getTrackedReminders()
    /// try trigger.syncTrackedReminders(tracked)
    ///
    /// // External tools can now monitor ~/.sysm-triggers.md
    /// print("Trigger file updated at \(Date())")
    /// ```
    func syncTrackedReminders(_ tracked: [(key: String, reminder: TrackedReminder)]) throws
}
