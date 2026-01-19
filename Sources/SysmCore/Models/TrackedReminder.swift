import Foundation

/// Tracks the state of a reminder across sessions for the `sysm today` command.
///
/// Used by the cache to remember which reminders have been seen, dismissed,
/// or completed, enabling persistent tracking of daily tasks.
public struct TrackedReminder: Codable {
    public var originalName: String
    public var firstSeen: String
    public var tracked: Bool
    public var dismissed: Bool
    public var project: String
    public var status: String
    public var completedDate: String?

    public enum CodingKeys: String, CodingKey {
        case originalName = "original_name"
        case firstSeen = "first_seen"
        case tracked
        case dismissed
        case project
        case status
        case completedDate = "completed_date"
    }

    public init(
        originalName: String,
        firstSeen: String = Self.todayString(),
        tracked: Bool = false,
        dismissed: Bool = false,
        project: String = "",
        status: String = "pending",
        completedDate: String? = nil
    ) {
        self.originalName = originalName
        self.firstSeen = firstSeen
        self.tracked = tracked
        self.dismissed = dismissed
        self.project = project
        self.status = status
        self.completedDate = completedDate
    }

    /// Returns today's date as a string in YYYY-MM-DD format.
    public static func todayString() -> String {
        DateFormatters.isoDate.string(from: Date())
    }

    /// Creates a normalized key from a reminder name for cache lookups.
    /// - Parameter name: The reminder name.
    /// - Returns: Lowercase, trimmed string for consistent lookups.
    public static func makeKey(_ name: String) -> String {
        return name.lowercased().trimmingCharacters(in: .whitespaces)
    }
}
