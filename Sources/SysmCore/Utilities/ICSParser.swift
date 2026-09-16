import EventKit
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
    /// The event's RRULE, when it carries one EventKit can express.
    public let recurrence: EKRecurrenceRule?

    public init(title: String, startDate: Date, endDate: Date, isAllDay: Bool, location: String?,
                notes: String?, uid: String?, organizer: String?, attendees: [String],
                recurrence: EKRecurrenceRule? = nil) {
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.location = location
        self.notes = notes
        self.uid = uid
        self.organizer = organizer
        self.attendees = attendees
        self.recurrence = recurrence
    }
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
            attendees: attendees,
            recurrence: data["RRULE"].flatMap { recurrenceRule(from: $0) }
        )
    }

    /// The EventKit rule an RRULE value describes (RFC 5545 3.3.10), or nil
    /// when it names no frequency EventKit knows.
    ///
    /// Import read no RRULE at all, so a weekly meeting sysm had exported came
    /// back as a single event on its first date. What EventKit cannot hold,
    /// EXDATE and per-occurrence overrides, is still left behind.
    func recurrenceRule(from value: String) -> EKRecurrenceRule? {
        var parts: [String: String] = [:]
        for piece in value.components(separatedBy: ";") {
            let pair = piece.components(separatedBy: "=")
            guard pair.count == 2 else { continue }
            let name = pair[0].trimmingCharacters(in: .whitespaces).uppercased()
            parts[name] = pair[1].trimmingCharacters(in: .whitespaces)
        }

        guard let frequency = Self.frequency(named: parts["FREQ"]) else { return nil }

        var end: EKRecurrenceEnd?
        if let count = parts["COUNT"].flatMap({ Int($0) }), count > 0 {
            end = EKRecurrenceEnd(occurrenceCount: count)
        } else if let until = parts["UNTIL"],
                  let date = parseDate(until, isAllDay: until.count == 8, tzid: nil) {
            end = EKRecurrenceEnd(end: date)
        }

        // EventKit raises on a part its frequency does not allow, and a file
        // can carry any combination, so each part is offered only where the
        // frequency accepts it.
        let monthly = frequency == .monthly
        let yearly = frequency == .yearly
        let days = frequency == .daily ? nil : parts["BYDAY"].flatMap {
            Self.daysOfTheWeek(in: $0, numbered: monthly || yearly)
        }

        return EKRecurrenceRule(
            recurrenceWith: frequency,
            interval: max(parts["INTERVAL"].flatMap { Int($0) } ?? 1, 1),
            daysOfTheWeek: days,
            daysOfTheMonth: monthly ? Self.numbers(in: parts["BYMONTHDAY"]) : nil,
            monthsOfTheYear: yearly ? Self.numbers(in: parts["BYMONTH"]) : nil,
            weeksOfTheYear: yearly ? Self.numbers(in: parts["BYWEEKNO"]) : nil,
            daysOfTheYear: yearly ? Self.numbers(in: parts["BYYEARDAY"]) : nil,
            setPositions: monthly || yearly ? Self.numbers(in: parts["BYSETPOS"]) : nil,
            end: end
        )
    }

    private static func frequency(named name: String?) -> EKRecurrenceFrequency? {
        switch name {
        case "DAILY": return .daily
        case "WEEKLY": return .weekly
        case "MONTHLY": return .monthly
        case "YEARLY": return .yearly
        default: return nil
        }
    }

    /// BYDAY codes, each optionally prefixed by the week it falls in, as in
    /// "-1FR" for the last Friday. Only a monthly or yearly rule may count
    /// weeks; elsewhere the prefix is dropped rather than refused.
    private static func daysOfTheWeek(in value: String, numbered: Bool) -> [EKRecurrenceDayOfWeek]? {
        let weekdays: [String: EKWeekday] = [
            "SU": .sunday, "MO": .monday, "TU": .tuesday, "WE": .wednesday,
            "TH": .thursday, "FR": .friday, "SA": .saturday,
        ]
        let days = value.components(separatedBy: ",").compactMap { piece -> EKRecurrenceDayOfWeek? in
            let code = piece.trimmingCharacters(in: .whitespaces).uppercased()
            guard code.count >= 2, let weekday = weekdays[String(code.suffix(2))] else { return nil }
            let week = numbered ? Int(code.dropLast(2)) ?? 0 : 0
            return EKRecurrenceDayOfWeek(weekday, weekNumber: week)
        }
        return days.isEmpty ? nil : days
    }

    private static func numbers(in value: String?) -> [NSNumber]? {
        guard let value else { return nil }
        let numbers = value.components(separatedBy: ",")
            .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        return numbers.isEmpty ? nil : numbers.map(NSNumber.init(value:))
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
