import ArgumentParser
import Foundation
import SysmCore

struct CalendarAttendees: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "attendees",
        abstract: "List attendees for a calendar event"
    )

    @Argument(help: "Event ID")
    var eventId: String

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let service = Services.calendar()
        let attendees = try await service.listAttendees(eventId: eventId)

        if json {
            try OutputFormatter.printJSON(attendees)
        } else {
            if attendees.isEmpty {
                print("No attendees for this event")
            } else {
                print("Attendees (\(attendees.count)):")
                for attendee in attendees {
                    print("  \(attendee.formatted)")
                    if let email = attendee.email {
                        print("    Email: \(email)")
                    }
                    print("    Status: \(attendee.status)")
                }
            }
        }
    }
}
