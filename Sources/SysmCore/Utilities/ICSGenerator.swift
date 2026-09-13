import EventKit
import Foundation

/// Generates iCalendar (.ics) format from EventKit events.
public struct ICSGenerator {
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()

    /// - Parameter timeZone: The zone all-day dates are written in. EventKit
    ///   returns floating all-day events at local midnight in the default
    ///   zone, so that is the default. Written in UTC, every all-day event
    ///   came out a day early anywhere east of Greenwich.
    public static func generate(events: [EKEvent], calendarName: String, timeZone: TimeZone = .current) -> String {
        let allDay = ICSAllDayDates(timeZone: timeZone)
        var ics = [String]()

        // Header
        ics.append("BEGIN:VCALENDAR")
        ics.append("VERSION:2.0")
        ics.append("PRODID:-//sysm//Calendar Export//EN")
        ics.append("CALSCALE:GREGORIAN")
        ics.append("METHOD:PUBLISH")
        ics.append("X-WR-CALNAME:\(calendarName)")

        // Events
        for event in events {
            ics.append(contentsOf: generateEvent(event, allDay: allDay))
        }

        // Footer
        ics.append("END:VCALENDAR")

        return ics.joined(separator: "\r\n")
    }

    private static func generateEvent(_ event: EKEvent, allDay: ICSAllDayDates) -> [String] {
        var lines = [String]()

        lines.append("BEGIN:VEVENT")

        // UID
        if let uid = event.eventIdentifier {
            lines.append("UID:\(uid)")
        } else {
            lines.append("UID:\(UUID().uuidString)")
        }

        // Dates
        if event.isAllDay {
            let end = allDay.exclusiveEnd(start: event.startDate, end: event.endDate)
            lines.append("DTSTART;VALUE=DATE:\(allDay.string(from: event.startDate))")
            lines.append("DTEND;VALUE=DATE:\(allDay.string(from: end))")
        } else {
            lines.append("DTSTART:\(dateFormatter.string(from: event.startDate))")
            lines.append("DTEND:\(dateFormatter.string(from: event.endDate))")
        }

        // Summary (title)
        if let title = event.title {
            lines.append("SUMMARY:\(escapeICS(title))")
        }

        // Location
        if let location = event.location {
            lines.append("LOCATION:\(escapeICS(location))")
        }

        // Description (notes)
        if let notes = event.notes {
            lines.append("DESCRIPTION:\(escapeICS(notes))")
        }

        // URL
        if let url = event.url {
            lines.append("URL:\(url.absoluteString)")
        }

        // Status/Availability
        switch event.availability {
        case .busy:
            lines.append("STATUS:CONFIRMED")
            lines.append("TRANSP:OPAQUE")
        case .free:
            lines.append("STATUS:CONFIRMED")
            lines.append("TRANSP:TRANSPARENT")
        case .tentative:
            lines.append("STATUS:TENTATIVE")
            lines.append("TRANSP:OPAQUE")
        case .unavailable:
            lines.append("STATUS:CANCELLED")
        case .notSupported:
            // The calendar does not track availability; emit no STATUS or TRANSP.
            break
        @unknown default:
            break
        }

        // Attendees
        if let attendees = event.attendees {
            for attendee in attendees {
                let email = attendee.url.absoluteString.replacingOccurrences(of: "mailto:", with: "")
                let name = attendee.name ?? email
                let partstat: String
                switch attendee.participantStatus {
                case .accepted: partstat = "ACCEPTED"
                case .declined: partstat = "DECLINED"
                case .tentative: partstat = "TENTATIVE"
                default: partstat = "NEEDS-ACTION"
                }
                lines.append("ATTENDEE;CN=\(escapeICS(name));CUTYPE=INDIVIDUAL;ROLE=REQ-PARTICIPANT;PARTSTAT=\(partstat):mailto:\(email)")
            }
        }

        // Organizer
        if let organizer = event.organizer {
            let email = organizer.url.absoluteString.replacingOccurrences(of: "mailto:", with: "")
            let name = organizer.name ?? email
            lines.append("ORGANIZER;CN=\(escapeICS(name)):mailto:\(email)")
        }

        // Creation/modification dates
        let now = dateFormatter.string(from: Date())
        lines.append("DTSTAMP:\(now)")
        lines.append("CREATED:\(now)")
        lines.append("LAST-MODIFIED:\(now)")

        lines.append("END:VEVENT")

        return lines
    }

    private static func escapeICS(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: ";", with: "\\;")
            .replacingOccurrences(of: ",", with: "\\,")
            .replacingOccurrences(of: "\n", with: "\\n")
    }
}

/// Date-only (`VALUE=DATE`) values for all-day events, read and written in
/// one time zone.
///
/// RFC 5545 makes a date-valued DTEND exclusive, while EventKit ends an
/// all-day event just before midnight on its last day. The two end
/// conversions keep an exported event and its re-import the same length.
struct ICSAllDayDates {
    private let formatter: DateFormatter
    private let calendar: Foundation.Calendar

    init(timeZone: TimeZone) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = timeZone
        var calendar = Foundation.Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        self.formatter = formatter
        self.calendar = calendar
    }

    func string(from date: Date) -> String {
        formatter.string(from: date)
    }

    func date(from string: String) -> Date? {
        formatter.date(from: string)
    }

    /// The DTEND day for an EventKit all-day event: the day after its last day.
    func exclusiveEnd(start: Date, end: Date) -> Date {
        let lastDay = calendar.startOfDay(for: max(end.addingTimeInterval(-1), start))
        return calendar.date(byAdding: .day, value: 1, to: lastDay)!
    }

    /// The EventKit end for a DTEND day: the last second of the day before.
    func inclusiveEnd(start: Date, exclusiveEnd: Date) -> Date {
        max(exclusiveEnd.addingTimeInterval(-1), start)
    }
}
