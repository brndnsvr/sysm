import ArgumentParser
import Foundation

struct CalendarEdit: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "edit",
        abstract: "Edit an existing calendar event"
    )

    @Argument(help: "Event title to find")
    var title: String

    @Option(name: .long, help: "New title")
    var newTitle: String?

    @Option(name: .long, help: "New start date/time")
    var start: String?

    @Option(name: .long, help: "New end date/time")
    var end: String?

    func run() async throws {
        var newStart: Date?
        var newEnd: Date?

        if let startStr = start {
            guard let parsed = DateParser.parse(startStr) else {
                throw CalendarError.invalidDateFormat(startStr)
            }
            newStart = parsed
        }

        if let endStr = end {
            guard let parsed = DateParser.parse(endStr) else {
                throw CalendarError.invalidDateFormat(endStr)
            }
            newEnd = parsed
        }

        if newTitle == nil && newStart == nil && newEnd == nil {
            print("Error: At least one of --new-title, --start, or --end must be specified")
            throw ExitCode.failure
        }

        let service = Services.calendar()
        let success = try await service.editEvent(
            title: title,
            newTitle: newTitle,
            newStart: newStart,
            newEnd: newEnd
        )

        if success {
            print("Updated event: \(title)")
            if let t = newTitle {
                print("  New title: \(t)")
            }
            if let s = newStart {
                print("  New start: \(DateFormatters.fullDateTime.string(from: s))")
            }
            if let e = newEnd {
                print("  New end: \(DateFormatters.fullDateTime.string(from: e))")
            }
        } else {
            print("Event '\(title)' not found")
            throw ExitCode.failure
        }
    }
}
