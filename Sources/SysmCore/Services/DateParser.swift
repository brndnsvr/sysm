import Foundation

/// Parses natural language date strings into `Date` objects.
///
/// Supports various formats including:
/// - Relative dates: "today", "tomorrow", "next Monday"
/// - Day names: "friday", "tue"
/// - ISO dates: "2024-01-15"
/// - Slash dates: "1/15", "1/15/24"
/// - Time specifications: "3pm", "15:30", "9:00 AM"
///
/// ## Example
/// ```swift
/// let parser = Services.dateParser()
/// parser.parse("tomorrow 3pm")  // Returns tomorrow at 3:00 PM
/// parser.parse("next friday")   // Returns next Friday at midnight
/// ```
public struct DateParser: DateParserProtocol {

    public init() {}

    // MARK: - Cached Regex Patterns

    private static let timePatterns: [NSRegularExpression] = {
        let patterns = [
            #"(\d{1,2}):(\d{2})\s*(am|pm)"#,
            #"(\d{1,2})\s*(am|pm)"#,
            #"(\d{1,2}):(\d{2})"#,
        ]
        return patterns.compactMap { try? NSRegularExpression(pattern: $0, options: .caseInsensitive) }
    }()

    private static let slashDateRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: #"(\d{1,2})/(\d{1,2})(?:/(\d{2,4}))?"#)
    }()

    // MARK: - Day Mappings

    private static let daysOfWeek: [String: Int] = [
        "sunday": 1, "sun": 1,
        "monday": 2, "mon": 2,
        "tuesday": 3, "tue": 3, "tues": 3,
        "wednesday": 4, "wed": 4,
        "thursday": 5, "thu": 5, "thurs": 5,
        "friday": 6, "fri": 6,
        "saturday": 7, "sat": 7,
    ]

    // MARK: - Instance Methods (Protocol Conformance)

    /// Parses a natural language date string.
    /// - Parameter input: The date string to parse.
    /// - Returns: The parsed date, or nil if parsing fails.
    public func parse(_ input: String) -> Date? {
        parse(input, now: Date())
    }

    /// Internal testable version of parse that accepts a custom reference date.
    /// - Parameters:
    ///   - input: The date string to parse.
    ///   - now: The reference date to use for relative date calculations.
    /// - Returns: The parsed date, or nil if parsing fails.
    internal func parse(_ input: String, now: Date) -> Date? {
        let text = input.lowercased().trimmingCharacters(in: .whitespaces)
        let calendar = Foundation.Calendar.current

        if text == "today" {
            return parseTime(from: text, baseDate: now) ?? now
        }

        if text == "tomorrow" || text.hasPrefix("tomorrow") {
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!
            return parseTime(from: text, baseDate: tomorrow) ?? tomorrow
        }

        // Handle "next [weekday]" - returns the next occurrence of the specified weekday.
        // "next" means we always skip today, even if today matches the target weekday.
        // Examples:
        //   - "next friday" on Tuesday → this Friday (3 days)
        //   - "next friday" on Friday → next Friday (7 days, skip today)
        if text.hasPrefix("next ") {
            let dayPart = text.replacingOccurrences(of: "next ", with: "").components(separatedBy: " ").first ?? ""
            if let targetDay = Self.daysOfWeek[dayPart] {
                let currentDay = calendar.component(.weekday, from: now)
                var daysToAdd = targetDay - currentDay
                // If target day has passed this week, or is today, move to next week
                if daysToAdd <= 0 {
                    daysToAdd += 7
                }
                let targetDate = calendar.date(byAdding: .day, value: daysToAdd, to: calendar.startOfDay(for: now))!
                return parseTime(from: text, baseDate: targetDate) ?? targetDate
            }
        }

        for (dayName, dayNum) in Self.daysOfWeek {
            if text.hasPrefix(dayName) || text.contains(" \(dayName)") {
                let currentDay = calendar.component(.weekday, from: now)
                var daysToAdd = dayNum - currentDay
                if daysToAdd <= 0 {
                    daysToAdd += 7
                }
                let targetDate = calendar.date(byAdding: .day, value: daysToAdd, to: calendar.startOfDay(for: now))!
                return parseTime(from: text, baseDate: targetDate) ?? targetDate
            }
        }

        if let isoDate = parseISO(text) {
            return isoDate
        }

        if let slashDate = parseSlashDate(text, now: now) {
            return parseTime(from: text, baseDate: slashDate) ?? slashDate
        }

        return parseTime(from: text, baseDate: now)
    }

    /// Extracts and parses a time component from text.
    /// - Parameters:
    ///   - text: Text potentially containing a time specification.
    ///   - baseDate: The base date to apply the time to.
    /// - Returns: A new date with the parsed time, or nil if no time found.
    public func parseTime(from text: String, baseDate: Date) -> Date? {
        let calendar = Foundation.Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: baseDate)

        for regex in Self.timePatterns {
            if let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {

                if let hourRange = Range(match.range(at: 1), in: text) {
                    var hour = Int(text[hourRange]) ?? 0

                    let minuteRange = match.numberOfRanges > 2 ? Range(match.range(at: 2), in: text) : nil
                    let minute: Int
                    if let minRange = minuteRange, let minStr = Int(text[minRange]), minStr < 60 {
                        minute = minStr
                    } else {
                        minute = 0
                    }

                    let ampmRange = Range(match.range(at: match.numberOfRanges - 1), in: text)
                    if let ampmR = ampmRange {
                        let ampm = String(text[ampmR]).lowercased()
                        if ampm == "pm" && hour < 12 {
                            hour += 12
                        } else if ampm == "am" && hour == 12 {
                            hour = 0
                        }
                    }

                    components.hour = hour
                    components.minute = minute
                    return calendar.date(from: components)
                }
            }
        }

        return nil
    }

    /// Parses an ISO 8601 formatted date (YYYY-MM-DD).
    /// - Parameter text: The ISO date string.
    /// - Returns: The parsed date, or nil if invalid.
    public func parseISO(_ text: String) -> Date? {
        if let date = DateFormatters.isoDate.date(from: text.components(separatedBy: " ").first ?? text) {
            return parseTime(from: text, baseDate: date) ?? date
        }
        return nil
    }

    /// Parses a slash-formatted date (M/D or M/D/YY).
    /// - Parameter text: The slash date string.
    /// - Returns: The parsed date, or nil if invalid.
    public func parseSlashDate(_ text: String) -> Date? {
        parseSlashDate(text, now: Date())
    }

    /// Internal testable version of parseSlashDate that accepts a custom reference date.
    /// - Parameters:
    ///   - text: The slash date string.
    ///   - now: The reference date to use for determining the current year.
    /// - Returns: The parsed date, or nil if invalid.
    internal func parseSlashDate(_ text: String, now: Date) -> Date? {
        guard let regex = Self.slashDateRegex,
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let monthRange = Range(match.range(at: 1), in: text),
              let dayRange = Range(match.range(at: 2), in: text) else {
            return nil
        }

        let month = Int(text[monthRange]) ?? 1
        let day = Int(text[dayRange]) ?? 1
        var year = Foundation.Calendar.current.component(.year, from: now)

        if match.numberOfRanges > 3, let yearRange = Range(match.range(at: 3), in: text) {
            if let y = Int(text[yearRange]) {
                year = y < 100 ? 2000 + y : y
            }
        }

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day

        return Foundation.Calendar.current.date(from: components)
    }
}
