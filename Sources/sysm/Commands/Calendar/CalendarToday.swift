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
        let service = CalendarService()
        let events = try await service.getTodayEvents()

        if json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(events)
            print(String(data: data, encoding: .utf8)!)
        } else {
            if events.isEmpty {
                print("No events today")
            } else {
                let formatter = DateFormatter()
                formatter.dateStyle = .full
                print("Events for \(formatter.string(from: Date())):")
                print("")
                for event in events {
                    print(event.formatted(showCalendar: showCalendar))
                }
            }
        }
    }
}
