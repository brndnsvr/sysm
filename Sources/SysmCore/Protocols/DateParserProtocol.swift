import Foundation

/// Protocol defining natural language date parsing operations.
///
/// Implementations handle parsing various date formats including
/// relative dates ("tomorrow"), day names ("friday"), and standard formats.
public protocol DateParserProtocol: Sendable {
    /// Parses a natural language date string.
    /// - Parameter input: The date string to parse.
    /// - Returns: The parsed date, or nil if parsing fails.
    func parse(_ input: String) -> Date?

    /// Extracts and parses a time component from text.
    /// - Parameters:
    ///   - text: Text potentially containing a time specification.
    ///   - baseDate: The base date to apply the time to.
    /// - Returns: A new date with the parsed time, or nil if no time found.
    func parseTime(from text: String, baseDate: Date) -> Date?

    /// Parses an ISO 8601 formatted date (YYYY-MM-DD).
    /// - Parameter text: The ISO date string.
    /// - Returns: The parsed date, or nil if invalid.
    func parseISO(_ text: String) -> Date?

    /// Parses a slash-formatted date (M/D or M/D/YY).
    /// - Parameter text: The slash date string.
    /// - Returns: The parsed date, or nil if invalid.
    func parseSlashDate(_ text: String) -> Date?
}
