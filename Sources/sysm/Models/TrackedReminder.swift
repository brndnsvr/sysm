import Foundation

/// Tracks the state of a reminder across sessions for the `sysm today` command.
///
/// Used by the cache to remember which reminders have been seen, dismissed,
/// or completed, enabling persistent tracking of daily tasks.
struct TrackedReminder: Codable {
    var originalName: String
    var firstSeen: String
    var tracked: Bool
    var dismissed: Bool
    var project: String
    var status: String
    var completedDate: String?

    enum CodingKeys: String, CodingKey {
        case originalName = "original_name"
        case firstSeen = "first_seen"
        case tracked
        case dismissed
        case project
        case status
        case completedDate = "completed_date"
    }

    init(
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
    static func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    /// Creates a normalized key from a reminder name for cache lookups.
    /// - Parameter name: The reminder name.
    /// - Returns: Lowercase, trimmed string for consistent lookups.
    static func makeKey(_ name: String) -> String {
        return name.lowercased().trimmingCharacters(in: .whitespaces)
    }
}
