import ArgumentParser
import Foundation

struct CalendarCalendars: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "calendars",
        abstract: "List all calendars"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let service = Services.calendar()
        let calendars = try await service.listCalendars()

        if json {
            try OutputFormatter.printJSON(calendars)
        } else {
            print("Calendars:")
            for cal in calendars {
                print("  - \(cal)")
            }
        }
    }
}
