import Foundation

/// Cached date formatters for efficient reuse.
///
/// DateFormatter creation is expensive (~1-2ms per instance). This utility
/// provides thread-safe cached formatters for common date formatting needs.
///
/// ## Usage
/// ```swift
/// let formatted = DateFormatters.shortDate.string(from: date)
/// let parsed = DateFormatters.iso8601.date(from: string)
/// ```
enum DateFormatters {
    // MARK: - ISO 8601 Formatters

    /// Standard ISO 8601 formatter with internet date/time.
    /// Format: "2024-01-15T10:30:00Z"
    static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    /// ISO 8601 formatter with fractional seconds.
    /// Format: "2024-01-15T10:30:00.123Z"
    static let iso8601WithFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    /// ISO 8601 date-only formatter.
    /// Format: "2024-01-15"
    static let iso8601DateOnly: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter
    }()

    // MARK: - Date-Only Formatters

    /// ISO date formatter (yyyy-MM-dd).
    /// Format: "2024-01-15"
    static let isoDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    /// Short date formatter.
    /// Format varies by locale: "1/15/24" (US)
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()

    /// Medium date formatter.
    /// Format varies by locale: "Jan 15, 2024" (US)
    static let mediumDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    /// Full date formatter.
    /// Format varies by locale: "Friday, January 15, 2024" (US)
    static let fullDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter
    }()

    // MARK: - Time-Only Formatters

    /// Short time formatter.
    /// Format varies by locale: "3:30 PM" (US)
    static let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    // MARK: - Date and Time Formatters

    /// Short date and time formatter.
    /// Format varies by locale: "1/15/24, 3:30 PM" (US)
    static let shortDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    /// Medium date and short time formatter.
    /// Format varies by locale: "Jan 15, 2024, 3:30 PM" (US)
    static let mediumDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    /// Full date and short time formatter.
    /// Format varies by locale: "Monday, January 15, 2024 at 3:30 PM" (US)
    static let fullDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter
    }()

    // MARK: - Specialized Formatters

    /// Day of week formatter.
    /// Format: "Monday"
    static let dayOfWeek: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()

    /// Short day of week formatter.
    /// Format: "Mon"
    static let shortDayOfWeek: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()

    /// Month and day formatter.
    /// Format: "Jan 15"
    static let monthDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    /// Hour and minute formatter (24h).
    /// Format: "15:30"
    static let hourMinute24: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    /// Hour-only formatter for weather displays.
    /// Format: "3 PM"
    static let hourOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        return formatter
    }()

    /// Date for file exports (safe for filenames).
    /// Format: "2024-01-15_153000"
    static let filenameSafe: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    // MARK: - Relative Date Formatting

    /// Relative date formatter for human-friendly output.
    /// Example: "today", "yesterday", "in 2 days"
    static let relative: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()
}
