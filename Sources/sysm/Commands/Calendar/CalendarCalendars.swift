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
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(calendars)
            print(String(data: data, encoding: .utf8)!)
        } else {
            print("Calendars:")
            for cal in calendars {
                print("  - \(cal)")
            }
        }
    }
}
