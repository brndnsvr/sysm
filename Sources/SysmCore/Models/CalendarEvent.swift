import EventKit
import Foundation

import ArgumentParser

/// Recurrence frequency for repeating events.
public enum RecurrenceFrequency: String, Codable, CaseIterable, ExpressibleByArgument {
    case daily
    case weekly
    case monthly
    case yearly

    public init?(from ekFrequency: EKRecurrenceFrequency) {
        switch ekFrequency {
        case .daily: self = .daily
        case .weekly: self = .weekly
        case .monthly: self = .monthly
        case .yearly: self = .yearly
        @unknown default: return nil
        }
    }

    public var ekFrequency: EKRecurrenceFrequency {
        switch self {
        case .daily: return .daily
        case .weekly: return .weekly
        case .monthly: return .monthly
        case .yearly: return .yearly
        }
    }
}

/// Represents a recurrence rule for repeating events.
public struct RecurrenceRule: Codable {
    public let frequency: RecurrenceFrequency
    public let interval: Int
    public let daysOfWeek: [Int]?
    public let endDate: Date?
    public let occurrenceCount: Int?

    public init(frequency: RecurrenceFrequency, interval: Int = 1, daysOfWeek: [Int]? = nil, endDate: Date? = nil, occurrenceCount: Int? = nil) {
        self.frequency = frequency
        self.interval = interval
        self.daysOfWeek = daysOfWeek
        self.endDate = endDate
        self.occurrenceCount = occurrenceCount
    }

    public init?(from ekRule: EKRecurrenceRule) {
        guard let freq = RecurrenceFrequency(from: ekRule.frequency) else { return nil }
        self.frequency = freq
        self.interval = ekRule.interval
        self.daysOfWeek = ekRule.daysOfTheWeek?.map { $0.dayOfTheWeek.rawValue }
        if let end = ekRule.recurrenceEnd {
            self.endDate = end.endDate
            self.occurrenceCount = end.occurrenceCount > 0 ? end.occurrenceCount : nil
        } else {
            self.endDate = nil
            self.occurrenceCount = nil
        }
    }

    public func toEKRecurrenceRule() -> EKRecurrenceRule {
        let daysOfTheWeek: [EKRecurrenceDayOfWeek]? = daysOfWeek?.compactMap { dayNum in
            guard let weekday = EKWeekday(rawValue: dayNum) else { return nil }
            return EKRecurrenceDayOfWeek(weekday)
        }

        let recurrenceEnd: EKRecurrenceEnd?
        if let endDate = endDate {
            recurrenceEnd = EKRecurrenceEnd(end: endDate)
        } else if let count = occurrenceCount {
            recurrenceEnd = EKRecurrenceEnd(occurrenceCount: count)
        } else {
            recurrenceEnd = nil
        }

        return EKRecurrenceRule(
            recurrenceWith: frequency.ekFrequency,
            interval: interval,
            daysOfTheWeek: daysOfTheWeek,
            daysOfTheMonth: nil,
            monthsOfTheYear: nil,
            weeksOfTheYear: nil,
            daysOfTheYear: nil,
            setPositions: nil,
            end: recurrenceEnd
        )
    }

    public var description: String {
        var desc = "Every"
        if interval > 1 {
            desc += " \(interval)"
        }
        switch frequency {
        case .daily: desc += interval > 1 ? " days" : " day"
        case .weekly: desc += interval > 1 ? " weeks" : " week"
        case .monthly: desc += interval > 1 ? " months" : " month"
        case .yearly: desc += interval > 1 ? " years" : " year"
        }
        if let days = daysOfWeek, !days.isEmpty {
            let dayNames = days.compactMap { dayNumber -> String? in
                let formatter = DateFormatter()
                formatter.locale = Locale.current
                guard dayNumber >= 1 && dayNumber <= 7 else { return nil }
                return formatter.weekdaySymbols[dayNumber - 1]
            }
            desc += " on \(dayNames.joined(separator: ", "))"
        }
        if let end = endDate {
            desc += " until \(DateFormatters.mediumDate.string(from: end))"
        } else if let count = occurrenceCount {
            desc += " (\(count) times)"
        }
        return desc
    }
}

/// Represents an event attendee.
public struct EventAttendee: Codable {
    public let name: String?
    public let email: String?
    public let status: String
    public let isOrganizer: Bool

    public init(from participant: EKParticipant) {
        self.name = participant.name
        self.email = participant.url.absoluteString.replacingOccurrences(of: "mailto:", with: "")
        self.isOrganizer = participant.isCurrentUser && participant.participantRole == .chair

        switch participant.participantStatus {
        case .accepted: self.status = "accepted"
        case .declined: self.status = "declined"
        case .tentative: self.status = "tentative"
        case .pending: self.status = "pending"
        case .delegated: self.status = "delegated"
        case .completed: self.status = "completed"
        case .inProcess: self.status = "in-process"
        case .unknown: self.status = "unknown"
        @unknown default: self.status = "unknown"
        }
    }

    public var formatted: String {
        let displayName = name ?? email ?? "Unknown"
        let statusIcon: String
        switch status {
        case "accepted": statusIcon = "✓"
        case "declined": statusIcon = "✗"
        case "tentative": statusIcon = "?"
        default: statusIcon = "○"
        }
        return "\(statusIcon) \(displayName)\(isOrganizer ? " (organizer)" : "")"
    }
}

/// Represents an event alarm/reminder.
public struct EventAlarm: Codable {
    public let triggerMinutes: Int
    public let type: String

    public init(triggerMinutes: Int, type: String = "display") {
        self.triggerMinutes = triggerMinutes
        self.type = type
    }

    public init(from ekAlarm: EKAlarm) {
        // relativeOffset is negative for alarms before the event
        self.triggerMinutes = Int(-ekAlarm.relativeOffset / 60)
        self.type = ekAlarm.type == .audio ? "audio" : "display"
    }

    public func toEKAlarm() -> EKAlarm {
        return EKAlarm(relativeOffset: TimeInterval(-triggerMinutes * 60))
    }

    public var description: String {
        if triggerMinutes == 0 {
            return "At time of event"
        } else if triggerMinutes < 60 {
            return "\(triggerMinutes) minute\(triggerMinutes == 1 ? "" : "s") before"
        } else if triggerMinutes < 1440 {
            let hours = triggerMinutes / 60
            return "\(hours) hour\(hours == 1 ? "" : "s") before"
        } else {
            let days = triggerMinutes / 1440
            return "\(days) day\(days == 1 ? "" : "s") before"
        }
    }
}

/// Event availability status.
public enum EventAvailability: String, Codable, CaseIterable, ExpressibleByArgument {
    case busy
    case free
    case tentative
    case unavailable

    public init(from ekAvailability: EKEventAvailability) {
        switch ekAvailability {
        case .notSupported: self = .busy
        case .busy: self = .busy
        case .free: self = .free
        case .tentative: self = .tentative
        case .unavailable: self = .unavailable
        @unknown default: self = .busy
        }
    }

    public var ekAvailability: EKEventAvailability {
        switch self {
        case .busy: return .busy
        case .free: return .free
        case .tentative: return .tentative
        case .unavailable: return .unavailable
        }
    }
}

/// Represents a calendar event from macOS Calendar.
///
/// This model wraps EventKit's `EKEvent` for JSON serialization and
/// provides convenient formatting methods for CLI output.
public struct CalendarEvent: Codable {
    public let id: String
    public let title: String
    public let calendarName: String
    public let startDate: Date
    public let endDate: Date
    public let isAllDay: Bool
    public let location: String?
    public let notes: String?
    public let url: String?
    public let availability: EventAvailability
    public let recurrenceRule: RecurrenceRule?
    public let attendees: [EventAttendee]?
    public let alarms: [EventAlarm]?
    public let hasRecurrence: Bool
    public let organizerName: String?

    /// Creates a CalendarEvent from an EventKit event.
    /// - Parameter ekEvent: The EventKit event to convert.
    public init(from ekEvent: EKEvent) {
        self.id = ekEvent.eventIdentifier ?? UUID().uuidString
        self.title = ekEvent.title ?? ""
        self.calendarName = ekEvent.calendar?.title ?? "Unknown"
        self.startDate = ekEvent.startDate
        self.endDate = ekEvent.endDate
        self.isAllDay = ekEvent.isAllDay
        self.location = ekEvent.location
        self.notes = ekEvent.notes
        self.url = ekEvent.url?.absoluteString
        self.availability = EventAvailability(from: ekEvent.availability)
        self.hasRecurrence = ekEvent.hasRecurrenceRules

        if let rules = ekEvent.recurrenceRules, let firstRule = rules.first {
            self.recurrenceRule = RecurrenceRule(from: firstRule)
        } else {
            self.recurrenceRule = nil
        }

        if let participants = ekEvent.attendees, !participants.isEmpty {
            self.attendees = participants.map { EventAttendee(from: $0) }
        } else {
            self.attendees = nil
        }

        if let ekAlarms = ekEvent.alarms, !ekAlarms.isEmpty {
            self.alarms = ekAlarms.map { EventAlarm(from: $0) }
        } else {
            self.alarms = nil
        }

        self.organizerName = ekEvent.organizer?.name
    }

    /// Formatted time range string (e.g., "10:00 AM - 11:00 AM" or "All day").
    public var timeRange: String {
        if isAllDay {
            return "All day"
        }
        return "\(DateFormatters.shortTime.string(from: startDate)) - \(DateFormatters.shortTime.string(from: endDate))"
    }

    /// Full date string for the event's start date.
    public var dateString: String {
        DateFormatters.mediumDate.string(from: startDate)
    }

    /// Formats the event for CLI display.
    /// - Parameter showCalendar: Whether to include the calendar name.
    /// - Parameter showDetails: Whether to show recurrence, attendees, and alarms.
    /// - Returns: Formatted string with time, title, location, and optionally calendar.
    public func formatted(showCalendar: Bool = false, showDetails: Bool = false) -> String {
        var result = "- \(timeRange): \(title)"
        if let loc = location, !loc.isEmpty {
            result += " @ \(loc)"
        }
        if hasRecurrence {
            result += " [repeating]"
        }
        if showCalendar {
            result += " [\(calendarName)]"
        }
        if showDetails {
            if let rule = recurrenceRule {
                result += "\n    Recurrence: \(rule.description)"
            }
            if let attendeeList = attendees, !attendeeList.isEmpty {
                result += "\n    Attendees: \(attendeeList.count)"
                for attendee in attendeeList {
                    result += "\n      \(attendee.formatted)"
                }
            }
            if let alarmList = alarms, !alarmList.isEmpty {
                result += "\n    Reminders: \(alarmList.map { $0.description }.joined(separator: ", "))"
            }
        }
        return result
    }

    /// Full detailed description for single event view.
    public var detailedDescription: String {
        var lines: [String] = []
        lines.append("Title: \(title)")
        lines.append("Calendar: \(calendarName)")
        lines.append("Date: \(dateString)")
        lines.append("Time: \(timeRange)")

        if let loc = location, !loc.isEmpty {
            lines.append("Location: \(loc)")
        }
        if let eventUrl = url {
            lines.append("URL: \(eventUrl)")
        }
        lines.append("Availability: \(availability.rawValue)")

        if let rule = recurrenceRule {
            lines.append("Recurrence: \(rule.description)")
        }

        if let alarmList = alarms, !alarmList.isEmpty {
            lines.append("Reminders: \(alarmList.map { $0.description }.joined(separator: ", "))")
        }

        if let attendeeList = attendees, !attendeeList.isEmpty {
            lines.append("Attendees (\(attendeeList.count)):")
            for attendee in attendeeList {
                lines.append("  \(attendee.formatted)")
            }
        }

        if let eventNotes = notes, !eventNotes.isEmpty {
            lines.append("Notes: \(eventNotes)")
        }

        return lines.joined(separator: "\n")
    }
}
