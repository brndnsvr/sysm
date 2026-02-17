import ArgumentParser
import Foundation
import SysmCore

struct OutlookCalendar_: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "calendar",
        abstract: "List upcoming Outlook calendar events"
    )

    @Option(name: .long, help: "Number of days to look ahead (default: 7)")
    var days: Int = 7

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.outlook()
        let events = try service.getCalendarEvents(days: days)

        if json {
            try OutputFormatter.printJSON(events)
        } else {
            if events.isEmpty {
                print("No upcoming events in the next \(days) day(s)")
            } else {
                print("Outlook Calendar (\(events.count) events):\n")
                for event in events {
                    let allDay = event.isAllDay ? " [All Day]" : ""
                    print("  [\(event.id)] \(event.subject)\(allDay)")
                    print("    \(event.startTime) - \(event.endTime)")
                    if let location = event.location { print("    Location: \(location)") }
                }
            }
        }
    }
}
