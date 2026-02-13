import Foundation

/// Protocol defining natural language date parsing operations.
///
/// This protocol handles parsing various date formats including relative dates ("tomorrow", "next week"),
/// day names ("friday", "monday"), ISO 8601 formats, slash-formatted dates, and time specifications.
/// Designed to provide flexible, user-friendly date input for calendar and reminder operations.
///
/// ## Supported Formats
///
/// - **Relative**: "today", "tomorrow", "yesterday", "next week", "in 3 days"
/// - **Day names**: "monday", "friday", "next tuesday"
/// - **ISO 8601**: "2024-03-15", "2024-03-15T14:30:00"
/// - **Slash format**: "3/15", "3/15/24", "03/15/2024"
/// - **Time specs**: "at 3pm", "at 14:30", "at 2:30pm"
///
/// ## Usage Example
///
/// ```swift
/// let parser = DateParser()
///
/// // Parse relative dates
/// if let tomorrow = parser.parse("tomorrow") {
///     print("Tomorrow: \(tomorrow)")
/// }
///
/// // Parse day names
/// if let friday = parser.parse("friday") {
///     print("Next Friday: \(friday)")
/// }
///
/// // Parse with time
/// let baseDate = Date()
/// if let scheduled = parser.parseTime(from: "at 3pm", baseDate: baseDate) {
///     print("Scheduled for 3pm: \(scheduled)")
/// }
///
/// // Parse ISO dates
/// if let date = parser.parseISO("2024-12-25") {
///     print("Christmas: \(date)")
/// }
/// ```
///
/// ## Thread Safety
///
/// Implementations are marked as `Sendable` and safe to use across actor boundaries.
/// Date parsing operations are synchronous and thread-safe.
///
/// ## Error Handling
///
/// Parse methods return nil for unparseable input rather than throwing errors.
/// This allows graceful handling of user input and fallback to alternative parsing strategies.
///
public protocol DateParserProtocol: Sendable {
    // MARK: - Main Parsing

    /// Parses a natural language date string.
    ///
    /// Attempts to parse the input using multiple strategies in order:
    /// 1. Relative dates (today, tomorrow, next week, etc.)
    /// 2. Named days (monday, friday, etc.)
    /// 3. ISO 8601 format (YYYY-MM-DD)
    /// 4. Slash format (M/D, M/D/YY)
    ///
    /// - Parameter input: The date string to parse (case-insensitive).
    /// - Returns: The parsed ``Date``, or nil if parsing fails.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let dates = [
    ///     parser.parse("today"),      // Today at current time
    ///     parser.parse("tomorrow"),   // Tomorrow at current time
    ///     parser.parse("friday"),     // Next Friday at current time
    ///     parser.parse("next week"),  // 7 days from now
    ///     parser.parse("2024-03-15"), // March 15, 2024 at midnight
    ///     parser.parse("3/15"),       // March 15 this year at midnight
    /// ]
    /// ```
    ///
    /// ## Notes
    ///
    /// - Day names refer to the next occurrence of that day (e.g., "friday" is next Friday)
    /// - Dates without time are set to midnight (start of day)
    /// - Relative dates use the current date/time as reference
    func parse(_ input: String) -> Date?

    // MARK: - Time Parsing

    /// Extracts and parses a time component from text.
    ///
    /// Looks for time specifications in the format "at HH:MM" or "at H{am|pm}" and combines
    /// them with the base date. Supports both 12-hour (with am/pm) and 24-hour formats.
    ///
    /// - Parameters:
    ///   - text: Text potentially containing a time specification (e.g., "meeting at 3pm").
    ///   - baseDate: The base date to apply the parsed time to.
    /// - Returns: A new ``Date`` with the parsed time applied to baseDate, or nil if no time found.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let today = Date()
    ///
    /// // 12-hour format
    /// let afternoon = parser.parseTime(from: "at 3pm", baseDate: today)
    /// let morning = parser.parseTime(from: "at 9:30am", baseDate: today)
    ///
    /// // 24-hour format
    /// let evening = parser.parseTime(from: "at 18:00", baseDate: today)
    /// ```
    ///
    /// ## Supported Formats
    ///
    /// - "at 3pm", "at 9am"
    /// - "at 3:30pm", "at 9:45am"
    /// - "at 14:30", "at 09:45"
    /// - "at 15:00"
    func parseTime(from text: String, baseDate: Date) -> Date?

    // MARK: - Specific Format Parsing

    /// Parses an ISO 8601 formatted date (YYYY-MM-DD).
    ///
    /// Parses dates in strict ISO 8601 format. The resulting date is set to midnight
    /// in the local timezone.
    ///
    /// - Parameter text: The ISO date string (e.g., "2024-03-15").
    /// - Returns: The parsed ``Date`` at midnight, or nil if format is invalid.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let date1 = parser.parseISO("2024-03-15")  // March 15, 2024
    /// let date2 = parser.parseISO("2024-12-25")  // December 25, 2024
    /// let invalid = parser.parseISO("24-3-15")   // nil (invalid format)
    /// ```
    ///
    /// ## Format Requirements
    ///
    /// - Year must be 4 digits (2000-2100)
    /// - Month must be 1-12 (can be zero-padded)
    /// - Day must be valid for the month (can be zero-padded)
    /// - Separators must be hyphens
    func parseISO(_ text: String) -> Date?

    /// Parses a slash-formatted date (M/D or M/D/YY).
    ///
    /// Parses dates in common US slash format. Supports both with and without year.
    /// When year is omitted, uses the current year. The resulting date is set to midnight
    /// in the local timezone.
    ///
    /// - Parameter text: The slash date string (e.g., "3/15" or "3/15/24").
    /// - Returns: The parsed ``Date`` at midnight, or nil if format is invalid.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Without year (uses current year)
    /// let date1 = parser.parseSlashDate("3/15")     // March 15 this year
    /// let date2 = parser.parseSlashDate("12/25")    // December 25 this year
    ///
    /// // With 2-digit year
    /// let date3 = parser.parseSlashDate("3/15/24")  // March 15, 2024
    /// let date4 = parser.parseSlashDate("12/25/23") // December 25, 2023
    /// ```
    ///
    /// ## Format Details
    ///
    /// - Month and day can be 1 or 2 digits
    /// - Year (if provided) should be 2 digits (assumes 20XX for YY values)
    /// - Month must be 1-12
    /// - Day must be valid for the month
    func parseSlashDate(_ text: String) -> Date?
}
