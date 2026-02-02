import ArgumentParser
import Foundation
import SysmCore

struct CalendarList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List events for a specific date or date range"
    )

    @Argument(help: "Date to show events for (e.g., 'tomorrow', 'next monday', '2025-01-15')")
    var date: String

    @Option(name: .long, help: "End date for range query")
    var endDate: String?

    @Option(name: .long, help: "Filter by calendar name")
    var calendar: String?

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    @Flag(name: .long, help: "Show calendar name for each event")
    var showCalendar = false

    func run() async throws {
        guard let startDate = Services.dateParser().parse(date) else {
            throw CalendarError.invalidDateFormat(date)
        }

        let cal = Foundation.Calendar.current
        let end: Date
        if let endDateStr = endDate {
            guard let parsedEnd = Services.dateParser().parse(endDateStr) else {
                throw CalendarError.invalidDateFormat(endDateStr)
            }
            end = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: parsedEnd))!
        } else {
            end = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: startDate))!
        }

        let service = Services.calendar()
        let events = try await service.getEvents(from: cal.startOfDay(for: startDate), to: end, calendar: calendar)

        if json {
            try OutputFormatter.printJSON(events)
        } else {
            if events.isEmpty {
                print("No events found")
            } else {
                if endDate != nil {
                    print("Events from \(DateFormatters.fullDate.string(from: startDate)):")
                } else {
                    print("Events for \(DateFormatters.fullDate.string(from: startDate)):")
                }
                print("")

                // Group events by date for range queries
                var eventsByDate: [String: [CalendarEvent]] = [:]
                for event in events {
                    let dateKey = DateFormatters.fullDate.string(from: event.startDate)
                    eventsByDate[dateKey, default: []].append(event)
                }

                let sortedDates = eventsByDate.keys.sorted { date1, date2 in
                    let events1 = eventsByDate[date1]!
                    let events2 = eventsByDate[date2]!
                    return events1.first!.startDate < events2.first!.startDate
                }

                for dateKey in sortedDates {
                    if endDate != nil {
                        print(dateKey)
                    }
                    for event in eventsByDate[dateKey]! {
                        print(event.formatted(showCalendar: showCalendar))
                    }
                    if endDate != nil {
                        print("")
                    }
                }
            }
        }
    }
}
