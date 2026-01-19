import ArgumentParser
import Foundation
import SysmCore

struct ContactsBirthdays: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "birthdays",
        abstract: "List upcoming birthdays"
    )

    @Option(name: .long, help: "Number of days to look ahead (default: 30)")
    var days: Int = 30

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let service = Services.contacts()
        let birthdays = try await service.getUpcomingBirthdays(days: days)

        if json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let jsonResults = birthdays.map { birthday -> [String: Any] in
                var result: [String: Any] = [
                    "name": birthday.name,
                    "daysUntil": birthday.daysUntil,
                ]
                if let month = birthday.birthday.month, let day = birthday.birthday.day {
                    result["month"] = month
                    result["day"] = day
                    if let year = birthday.birthday.year {
                        result["year"] = year
                    }
                }
                return result
            }

            // Manual JSON encoding since we have mixed types
            let jsonData = try JSONSerialization.data(withJSONObject: jsonResults, options: .prettyPrinted)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print(jsonString)
            }
        } else {
            if birthdays.isEmpty {
                print("No birthdays in the next \(days) days")
            } else {
                print("Upcoming Birthdays (next \(days) days):")
                for birthday in birthdays {
                    let dateStr: String
                    if let month = birthday.birthday.month, let day = birthday.birthday.day {
                        let monthName = Foundation.Calendar.current.monthSymbols[month - 1]
                        dateStr = "\(monthName) \(day)"
                    } else {
                        dateStr = "Unknown"
                    }

                    let daysStr: String
                    switch birthday.daysUntil {
                    case 0:
                        daysStr = "Today!"
                    case 1:
                        daysStr = "Tomorrow"
                    default:
                        daysStr = "in \(birthday.daysUntil) days"
                    }

                    print("  \(birthday.name) - \(dateStr) (\(daysStr))")
                }
            }
        }
    }
}
