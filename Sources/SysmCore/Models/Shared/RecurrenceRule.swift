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
    public let daysOfTheMonth: [Int]?
    public let monthsOfTheYear: [Int]?
    public let weeksOfTheYear: [Int]?
    public let daysOfTheYear: [Int]?
    public let setPositions: [Int]?
    public let endDate: Date?
    public let occurrenceCount: Int?

    public init(frequency: RecurrenceFrequency, interval: Int = 1, daysOfWeek: [Int]? = nil,
                daysOfTheMonth: [Int]? = nil, monthsOfTheYear: [Int]? = nil,
                weeksOfTheYear: [Int]? = nil, daysOfTheYear: [Int]? = nil,
                setPositions: [Int]? = nil, endDate: Date? = nil, occurrenceCount: Int? = nil) {
        self.frequency = frequency
        self.interval = interval
        self.daysOfWeek = daysOfWeek
        self.daysOfTheMonth = daysOfTheMonth
        self.monthsOfTheYear = monthsOfTheYear
        self.weeksOfTheYear = weeksOfTheYear
        self.daysOfTheYear = daysOfTheYear
        self.setPositions = setPositions
        self.endDate = endDate
        self.occurrenceCount = occurrenceCount
    }

    public init?(from ekRule: EKRecurrenceRule) {
        guard let freq = RecurrenceFrequency(from: ekRule.frequency) else { return nil }
        self.frequency = freq
        self.interval = ekRule.interval
        self.daysOfWeek = ekRule.daysOfTheWeek?.map { $0.dayOfTheWeek.rawValue }
        self.daysOfTheMonth = ekRule.daysOfTheMonth as? [Int]
        self.monthsOfTheYear = ekRule.monthsOfTheYear as? [Int]
        self.weeksOfTheYear = ekRule.weeksOfTheYear as? [Int]
        self.daysOfTheYear = ekRule.daysOfTheYear as? [Int]
        self.setPositions = ekRule.setPositions as? [Int]
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
            daysOfTheMonth: daysOfTheMonth as [NSNumber]?,
            monthsOfTheYear: monthsOfTheYear as [NSNumber]?,
            weeksOfTheYear: weeksOfTheYear as [NSNumber]?,
            daysOfTheYear: daysOfTheYear as [NSNumber]?,
            setPositions: setPositions as [NSNumber]?,
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
        if let daysOfMonth = daysOfTheMonth, !daysOfMonth.isEmpty {
            let ordinals = daysOfMonth.map { "\($0)\(ordinalSuffix(for: $0))" }
            desc += " on the \(ordinals.joined(separator: ", "))"
        }
        if let months = monthsOfTheYear, !months.isEmpty {
            let monthNames = months.compactMap { monthNumber -> String? in
                let formatter = DateFormatter()
                formatter.locale = Locale.current
                guard monthNumber >= 1 && monthNumber <= 12 else { return nil }
                return formatter.monthSymbols[monthNumber - 1]
            }
            desc += " in \(monthNames.joined(separator: ", "))"
        }
        if let positions = setPositions, !positions.isEmpty {
            let posDesc = positions.map { pos in
                if pos == -1 { return "last" }
                else if pos == 1 { return "first" }
                else if pos > 0 { return "\(pos)\(ordinalSuffix(for: pos))" }
                else { return "\(-pos)\(ordinalSuffix(for: -pos)) from end" }
            }.joined(separator: ", ")
            desc += " (\(posDesc))"
        }
        if let end = endDate {
            desc += " until \(DateFormatters.mediumDate.string(from: end))"
        } else if let count = occurrenceCount {
            desc += " (\(count) times)"
        }
        return desc
    }

    private func ordinalSuffix(for number: Int) -> String {
        let absNumber = abs(number)
        let lastDigit = absNumber % 10
        let lastTwoDigits = absNumber % 100

        if lastTwoDigits >= 11 && lastTwoDigits <= 13 {
            return "th"
        }

        switch lastDigit {
        case 1: return "st"
        case 2: return "nd"
        case 3: return "rd"
        default: return "th"
        }
    }
}
