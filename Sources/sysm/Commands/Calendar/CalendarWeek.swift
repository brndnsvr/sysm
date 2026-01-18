import ArgumentParser
import Foundation

struct CalendarWeek: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "week",
        abstract: "Show this week's events"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    @Flag(name: .long, help: "Show calendar name for each event")
    var showCalendar = false

    func run() async throws {
        let service = Services.calendar()
        let events = try await service.getWeekEvents()

        if json {
            try OutputFormatter.printJSON(events)
        } else {
            if events.isEmpty {
                print("No events this week")
            } else {
                print("Events for the next 7 days:")
                print("")

                // Group events by date
                var eventsByDate: [String: [CalendarEvent]] = [:]
                for event in events {
                    let dateKey = DateFormatters.fullDate.string(from: event.startDate)
                    eventsByDate[dateKey, default: []].append(event)
                }

                // Sort dates and print
                let sortedDates = eventsByDate.keys.sorted { date1, date2 in
                    let events1 = eventsByDate[date1]!
                    let events2 = eventsByDate[date2]!
                    return events1.first!.startDate < events2.first!.startDate
                }

                for dateKey in sortedDates {
                    print(dateKey)
                    for event in eventsByDate[dateKey]! {
                        print(event.formatted(showCalendar: showCalendar))
                    }
                    print("")
                }
            }
        }
    }
}
