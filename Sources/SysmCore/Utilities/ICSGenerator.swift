import EventKit
import Foundation

/// Generates iCalendar (.ics) format from EventKit events.
public struct ICSGenerator {
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

    public static func generate(events: [EKEvent], calendarName: String) -> String {
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
            ics.append(contentsOf: generateEvent(event))
        }

        // Footer
        ics.append("END:VCALENDAR")

        return ics.joined(separator: "\r\n")
    }

    private static func generateEvent(_ event: EKEvent) -> [String] {
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
            lines.append("DTSTART;VALUE=DATE:\(dateOnlyFormatter.string(from: event.startDate))")
            lines.append("DTEND;VALUE=DATE:\(dateOnlyFormatter.string(from: event.endDate))")
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
        @unknown default:
            break
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
