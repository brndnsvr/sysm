import Foundation

struct DateParser {
    static let daysOfWeek: [String: Int] = [
        "sunday": 1, "sun": 1,
        "monday": 2, "mon": 2,
        "tuesday": 3, "tue": 3, "tues": 3,
        "wednesday": 4, "wed": 4,
        "thursday": 5, "thu": 5, "thurs": 5,
        "friday": 6, "fri": 6,
        "saturday": 7, "sat": 7,
    ]

    static func parse(_ input: String) -> Date? {
        let text = input.lowercased().trimmingCharacters(in: .whitespaces)
        let now = Date()
        let calendar = Foundation.Calendar.current

        if text == "today" {
            return parseTime(from: text, baseDate: now) ?? now
        }

        if text == "tomorrow" || text.hasPrefix("tomorrow") {
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!
            return parseTime(from: text, baseDate: tomorrow) ?? tomorrow
        }

        if text.hasPrefix("next ") {
            let dayPart = text.replacingOccurrences(of: "next ", with: "").components(separatedBy: " ").first ?? ""
            if let targetDay = daysOfWeek[dayPart] {
                let currentDay = calendar.component(.weekday, from: now)
                var daysToAdd = targetDay - currentDay
                if daysToAdd <= 0 {
                    daysToAdd += 7
                }
                let targetDate = calendar.date(byAdding: .day, value: daysToAdd, to: calendar.startOfDay(for: now))!
                return parseTime(from: text, baseDate: targetDate) ?? targetDate
            }
        }

        for (dayName, dayNum) in daysOfWeek {
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

        if let slashDate = parseSlashDate(text) {
            return parseTime(from: text, baseDate: slashDate) ?? slashDate
        }

        return parseTime(from: text, baseDate: now)
    }

    static func parseTime(from text: String, baseDate: Date) -> Date? {
        let calendar = Foundation.Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: baseDate)

        let patterns: [(String, (Int, Int) -> Void)] = [
            (#"(\d{1,2}):(\d{2})\s*(am|pm)"#, { hour, minute in
                components.hour = hour
                components.minute = minute
            }),
            (#"(\d{1,2})\s*(am|pm)"#, { hour, _ in
                components.hour = hour
                components.minute = 0
            }),
            (#"(\d{1,2}):(\d{2})"#, { hour, minute in
                components.hour = hour
                components.minute = minute
            }),
        ]

        for (pattern, _) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {

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

    static func parseISO(_ text: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: text.components(separatedBy: " ").first ?? text) {
            return parseTime(from: text, baseDate: date) ?? date
        }
        return nil
    }

    static func parseSlashDate(_ text: String) -> Date? {
        let pattern = #"(\d{1,2})/(\d{1,2})(?:/(\d{2,4}))?"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let monthRange = Range(match.range(at: 1), in: text),
              let dayRange = Range(match.range(at: 2), in: text) else {
            return nil
        }

        let month = Int(text[monthRange]) ?? 1
        let day = Int(text[dayRange]) ?? 1
        var year = Foundation.Calendar.current.component(.year, from: Date())

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
