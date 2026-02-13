import ArgumentParser
import Foundation
import SysmCore

struct CalendarCalendars: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "calendars",
        abstract: "List all calendars"
    )

    @Flag(name: .long, help: "Show detailed calendar information")
    var details = false

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let service = Services.calendar()

        if details {
            let calendars = try await service.listCalendarsDetailed()

            if json {
                try OutputFormatter.printJSON(calendars)
            } else {
                print("Calendars (\(calendars.count)):")
                for cal in calendars {
                    print("\n  \(cal.title)")
                    print("    ID: \(cal.identifier)")
                    print("    Type: \(cal.type)")
                    print("    Color: \(cal.color)")
                    if let source = cal.source {
                        print("    Source: \(source)")
                    }
                    print("    Modifiable: \(cal.allowsContentModifications ? "yes" : "no")")
                    if cal.isSubscribed {
                        print("    Subscribed: yes")
                    }
                }
            }
        } else {
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
}
