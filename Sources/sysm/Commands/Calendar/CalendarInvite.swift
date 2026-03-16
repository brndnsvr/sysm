import ArgumentParser
import Foundation
import SysmCore

struct CalendarInvite: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "invite",
        abstract: "Add attendees to an existing calendar event"
    )

    @Argument(help: "Event ID (from calendar show/today/list --json)")
    var eventId: String

    @Option(name: .long, parsing: .upToNextOption, help: "Attendee email addresses")
    var attendee: [String]

    @Option(name: .long, help: "Calendar name (helps narrow CalDAV search)")
    var calendar: String?

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let caldav = Services.caldav()
        guard caldav.isConfigured() else {
            throw CalDAVError.notConfigured
        }

        guard !attendee.isEmpty else {
            print("Error: At least one --attendee email is required")
            throw ExitCode.failure
        }

        // Look up event via EventKit to get the CalDAV UID
        let calendarService = Services.calendar()
        guard let event = try await calendarService.getEvent(id: eventId) else {
            throw CalendarError.eventNotFound(eventId)
        }

        guard let externalID = event.externalID else {
            throw CalDAVError.syncPending
        }

        // Add attendees via CalDAV
        try await caldav.addAttendees(
            emails: attendee,
            toEventUID: externalID,
            calendarName: calendar ?? event.calendarName,
            organizerEmail: nil
        )

        if json {
            let result: [String: Any] = [
                "eventId": eventId,
                "title": event.title,
                "attendeesAdded": attendee,
            ]
            let data = try JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys])
            print(String(data: data, encoding: .utf8) ?? "")
        } else {
            print("Invitations sent for '\(event.title)':")
            for email in attendee {
                print("  \(email)")
            }
        }
    }
}
