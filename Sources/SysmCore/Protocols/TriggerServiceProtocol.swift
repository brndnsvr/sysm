import Foundation

/// Protocol defining trigger file synchronization operations.
///
/// Implementations handle syncing tracked reminders to a markdown trigger file
/// for external tool integration.
public protocol TriggerServiceProtocol: Sendable {
    /// Syncs tracked reminders to the trigger file.
    /// - Parameter tracked: Array of tracked reminders.
    func syncTrackedReminders(_ tracked: [(key: String, reminder: TrackedReminder)]) throws
}
