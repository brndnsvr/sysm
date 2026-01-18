import ArgumentParser
import Foundation

struct CalendarToday: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "today",
        abstract: "Show today's events"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    @Flag(name: .long, help: "Show calendar name for each event")
    var showCalendar = false

    func run() async throws {
        let service = Services.calendar()
        let events = try await service.getTodayEvents()

        if json {
            try OutputFormatter.printJSON(events)
        } else {
            if events.isEmpty {
                print("No events today")
            } else {
                print("Events for \(DateFormatters.fullDate.string(from: Date())):")
                print("")
                for event in events {
                    print(event.formatted(showCalendar: showCalendar))
                }
            }
        }
    }
}
