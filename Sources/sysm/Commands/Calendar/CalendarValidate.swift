import ArgumentParser
import Foundation

struct CalendarValidate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "validate",
        abstract: "Check for events with invalid dates"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let service = CalendarService()
        let invalidEvents = try await service.validateEvents()

        if json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(invalidEvents)
            print(String(data: data, encoding: .utf8)!)
        } else {
            if invalidEvents.isEmpty {
                print("All events have valid dates (2000-2100)")
            } else {
                print("Found \(invalidEvents.count) event(s) with invalid dates:")
                print("")
                for event in invalidEvents {
                    let year = Foundation.Calendar.current.component(.year, from: event.startDate)
                    print("- \(event.title)")
                    print("  Calendar: \(event.calendarName)")
                    print("  Year: \(year)")
                    print("  ID: \(event.id)")
                    print("")
                }
            }
        }
    }
}
