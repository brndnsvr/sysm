import ArgumentParser
import Foundation
import SysmCore

struct CalendarShow: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "show",
        abstract: "Show details for a specific event by ID"
    )

    @Argument(help: "Event ID (use 'sysm calendar today --json' to find IDs)")
    var eventId: String

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let service = Services.calendar()

        guard let event = try await service.getEvent(id: eventId) else {
            fputs("Event not found: \(eventId)\n", stderr)
            throw ExitCode.failure
        }

        if json {
            try OutputFormatter.printJSON(event)
        } else {
            print(event.detailedDescription)
            print("\nID: \(event.id)")
        }
    }
}
