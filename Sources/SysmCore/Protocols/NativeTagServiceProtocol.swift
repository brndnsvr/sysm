import Foundation

/// Protocol for reading and writing native Reminders tags via the SQLite database.
///
/// Native tags appear as tag pills in Reminders.app and work with smart lists,
/// unlike hashtag-in-notes tags which are invisible to the app's tag system.
///
/// This service accesses the Reminders Core Data SQLite database directly.
/// It is struct-based (not actor) since SQLite handles its own concurrency.
public protocol NativeTagServiceProtocol: Sendable {
    /// Lists all native tags with their reminder counts.
    func listTags() throws -> [NativeTag]

    /// Gets native tags for a specific reminder by its EventKit ID.
    func getTagsForReminder(eventKitId: String) throws -> [String]

    /// Adds a native tag to a reminder. Returns true if the tag was added, false if already present.
    func addTag(_ name: String, toReminder eventKitId: String) throws -> Bool

    /// Removes a native tag from a reminder. Returns true if removed, false if not found.
    func removeTag(_ name: String, fromReminder eventKitId: String) throws -> Bool

    /// Creates a backup of the Reminders database. Returns the backup file path.
    func backupDatabase() throws -> String
}
