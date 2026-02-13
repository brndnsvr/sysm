import Foundation

/// Parsed event data from iCalendar file.
public struct ICSEventData {
    public let title: String
    public let startDate: Date
    public let endDate: Date
    public let isAllDay: Bool
    public let location: String?
    public let notes: String?
}

/// Parses iCalendar (.ics) format.
public struct ICSParser {
    private let content: String

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()

    private static let dateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()

    public init(content: String) {
        self.content = content
    }

    public func parse() throws -> [ICSEventData] {
        var events = [ICSEventData]()
        let lines = content.components(separatedBy: .newlines)

        var inEvent = false
        var currentEvent: [String: String] = [:]

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed == "BEGIN:VEVENT" {
                inEvent = true
                currentEvent = [:]
            } else if trimmed == "END:VEVENT" {
                if let event = parseEvent(from: currentEvent) {
                    events.append(event)
                }
                inEvent = false
            } else if inEvent {
                // Parse property
                if let colonIndex = trimmed.firstIndex(of: ":") {
                    let key = String(trimmed[..<colonIndex])
                    let value = String(trimmed[trimmed.index(after: colonIndex)...])

                    // Handle properties with parameters (e.g., DTSTART;VALUE=DATE:20260101)
                    let propertyName = key.components(separatedBy: ";")[0]
                    currentEvent[propertyName] = value
                }
            }
        }

        return events
    }

    private func parseEvent(from data: [String: String]) -> ICSEventData? {
        guard let summary = data["SUMMARY"],
              let dtstart = data["DTSTART"],
              let dtend = data["DTEND"] else {
            return nil
        }

        // Determine if all-day event
        let isAllDay = dtstart.count == 8 // YYYYMMDD format

        // Parse dates
        guard let startDate = parseDate(dtstart, isAllDay: isAllDay),
              let endDate = parseDate(dtend, isAllDay: isAllDay) else {
            return nil
        }

        let location = data["LOCATION"].map { unescapeICS($0) }
        let notes = data["DESCRIPTION"].map { unescapeICS($0) }

        return ICSEventData(
            title: unescapeICS(summary),
            startDate: startDate,
            endDate: endDate,
            isAllDay: isAllDay,
            location: location,
            notes: notes
        )
    }

    private func parseDate(_ dateString: String, isAllDay: Bool) -> Date? {
        if isAllDay {
            return Self.dateOnlyFormatter.date(from: dateString)
        } else {
            return Self.dateFormatter.date(from: dateString)
        }
    }

    private func unescapeICS(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\\,", with: ",")
            .replacingOccurrences(of: "\\;", with: ";")
            .replacingOccurrences(of: "\\\\", with: "\\")
    }
}
