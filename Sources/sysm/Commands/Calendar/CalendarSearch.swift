import ArgumentParser
import Foundation

struct CalendarSearch: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "search",
        abstract: "Search for events by title, location, or notes"
    )

    @Argument(help: "Search query")
    var query: String

    @Option(name: .long, help: "Number of days ahead to search (default: 30)")
    var days: Int = 30

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    @Flag(name: .long, help: "Show calendar name for each event")
    var showCalendar = false

    func run() async throws {
        let service = Services.calendar()
        let events = try await service.searchEvents(query: query, daysAhead: days)

        if json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(events)
            print(String(data: data, encoding: .utf8)!)
        } else {
            if events.isEmpty {
                print("No events found matching '\(query)'")
            } else {
                print("Found \(events.count) event(s) matching '\(query)':")
                print("")

                // Group events by date
                var eventsByDate: [String: [CalendarEvent]] = [:]
                let formatter = DateFormatter()
                formatter.dateStyle = .full

                for event in events {
                    let dateKey = formatter.string(from: event.startDate)
                    eventsByDate[dateKey, default: []].append(event)
                }

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
