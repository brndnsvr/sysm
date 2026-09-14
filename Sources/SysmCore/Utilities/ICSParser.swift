import Foundation

/// Parsed event data from iCalendar file.
public struct ICSEventData {
    public let title: String
    public let startDate: Date
    public let endDate: Date
    public let isAllDay: Bool
    public let location: String?
    public let notes: String?
    public let uid: String?
    public let organizer: String?
    public let attendees: [String]
}

/// Parses iCalendar (.ics) format.
public struct ICSParser {
    private let content: String
    private let timeZone: TimeZone
    private let allDay: ICSAllDayDates

    private static let utcFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()

    /// - Parameters:
    ///   - content: The iCalendar text.
    ///   - timeZone: The zone for floating times and all-day dates, which carry
    ///     no zone of their own and belong to wherever the calendar is used.
    ///     Read in UTC, all-day dates landed on the previous day anywhere west
    ///     of Greenwich.
    public init(content: String, timeZone: TimeZone = .current) {
        self.content = content
        self.timeZone = timeZone
        self.allDay = ICSAllDayDates(timeZone: timeZone)
    }

    public func parse() throws -> [ICSEventData] {
        // RFC 5545: Unfold continuation lines (CRLF + space/tab joins to previous line)
        let unfolded = content
            .replacingOccurrences(of: "\r\n ", with: "")
            .replacingOccurrences(of: "\r\n\t", with: "")
            .replacingOccurrences(of: "\n ", with: "")
            .replacingOccurrences(of: "\n\t", with: "")

        var events = [ICSEventData]()
        let lines = unfolded.components(separatedBy: .newlines)

        var inEvent = false
        var currentEvent: [String: String] = [:]
        var currentZones: [String: String] = [:]
        var currentAttendees: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed == "BEGIN:VEVENT" {
                inEvent = true
                currentEvent = [:]
                currentZones = [:]
                currentAttendees = []
            } else if trimmed == "END:VEVENT" {
                if let event = parseEvent(from: currentEvent, zones: currentZones, attendees: currentAttendees) {
                    events.append(event)
                }
                inEvent = false
            } else if inEvent {
                // Parse property
                if let colonIndex = Self.valueSeparator(in: trimmed) {
                    let key = String(trimmed[..<colonIndex])
                    let value = String(trimmed[trimmed.index(after: colonIndex)...])

                    // Properties can carry parameters, e.g. DTSTART;TZID=America/New_York:20260115T090000
                    let keyParts = key.components(separatedBy: ";")
                    let propertyName = keyParts[0]

                    // ATTENDEE can appear multiple times
                    if propertyName == "ATTENDEE" {
                        currentAttendees.append(trimmed)
                    } else {
                        currentEvent[propertyName] = value
                        if let zone = Self.timeZoneParameter(in: keyParts.dropFirst()) {
                            currentZones[propertyName] = zone
                        }
                    }
                }
            }
        }

        return events
    }

    /// The colon that ends a property's name and parameters, skipping colons
    /// inside quoted parameter values such as TZID="(UTC-05:00) Eastern Time".
    static func valueSeparator(in line: String) -> String.Index? {
        var quoted = false
        for index in line.indices {
            switch line[index] {
            case "\"":
                quoted.toggle()
            case ":" where !quoted:
                return index
            default:
                continue
            }
        }
        return nil
    }

    private static func timeZoneParameter(in parameters: ArraySlice<String>) -> String? {
        guard let parameter = parameters.first(where: { $0.uppercased().hasPrefix("TZID=") }) else {
            return nil
        }
        return String(parameter.dropFirst(5)).trimmingCharacters(in: CharacterSet(charactersIn: "\""))
    }

    private func parseEvent(from data: [String: String], zones: [String: String], attendees: [String]) -> ICSEventData? {
        guard let summary = data["SUMMARY"],
              let dtstart = data["DTSTART"],
              let dtend = data["DTEND"] else {
            return nil
        }

        // Determine if all-day event
        let isAllDay = dtstart.count == 8 // YYYYMMDD format

        // Parse dates
        guard let startDate = parseDate(dtstart, isAllDay: isAllDay, tzid: zones["DTSTART"]),
              let rawEndDate = parseDate(dtend, isAllDay: isAllDay, tzid: zones["DTEND"]) else {
            return nil
        }

        // A date-valued DTEND is exclusive; EventKit ends an all-day event
        // within its last day.
        let endDate = isAllDay ? allDay.inclusiveEnd(start: startDate, exclusiveEnd: rawEndDate) : rawEndDate

        let location = data["LOCATION"].map { unescapeICS($0) }
        let notes = data["DESCRIPTION"].map { unescapeICS($0) }

        return ICSEventData(
            title: unescapeICS(summary),
            startDate: startDate,
            endDate: endDate,
            isAllDay: isAllDay,
            location: location,
            notes: notes,
            uid: data["UID"],
            organizer: data["ORGANIZER"],
            attendees: attendees
        )
    }

    /// Reads a DATE or DATE-TIME value: UTC when it ends in Z, local time in
    /// its TZID zone, or floating (no zone), which belongs in the parser's zone.
    ///
    /// Only the UTC form used to parse, so every event given with a TZID, as
    /// Outlook and Google Calendar write them, or with a floating time was
    /// dropped without a word. A TZID Foundation does not know, such as a
    /// Windows zone name, is read as floating rather than dropped.
    private func parseDate(_ value: String, isAllDay: Bool, tzid: String?) -> Date? {
        if isAllDay {
            return allDay.date(from: value)
        }
        if value.hasSuffix("Z") {
            return Self.utcFormatter.date(from: value)
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd'T'HHmmss"
        formatter.timeZone = tzid.flatMap { TimeZone(identifier: $0) } ?? timeZone
        return formatter.date(from: value)
    }

    private func unescapeICS(_ text: String) -> String {
        // RFC 5545: Process escaped backslash first via placeholder to prevent
        // double-unescaping (e.g., \\n in ICS should become \n literal, not newline)
        return text
            .replacingOccurrences(of: "\\\\", with: "\u{0000}")
            .replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\\N", with: "\n")
            .replacingOccurrences(of: "\\,", with: ",")
            .replacingOccurrences(of: "\\;", with: ";")
            .replacingOccurrences(of: "\u{0000}", with: "\\")
    }
}
