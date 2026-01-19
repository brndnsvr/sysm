import Foundation

/// Persistent cache for sysm state stored at ~/.sysm/cache.json.
///
/// Currently tracks reminder state for the `sysm today` command.
/// Extensible for future caching needs (events, notes, etc.).
public struct SysmCache: Codable {
    public var seenReminders: [String: TrackedReminder]
    public var events: [String: AnyCodable]?
    public var reminders: [String: AnyCodable]?
    public var notes: [String: AnyCodable]?

    public enum CodingKeys: String, CodingKey {
        case seenReminders = "seen_reminders"
        case events
        case reminders
        case notes
    }

    public init() {
        self.seenReminders = [:]
    }
}
