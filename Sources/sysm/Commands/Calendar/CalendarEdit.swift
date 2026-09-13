import ArgumentParser
import Foundation
import SysmCore

struct CalendarEdit: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "edit",
        abstract: "Edit an existing calendar event",
        discussion: """
        A recurring event's occurrences share one title and ID. The next \
        occurrence that has not ended is changed; add --future to change it \
        and every later occurrence.
        """
    )

    @Argument(help: "Exact title of the event to edit")
    var title: String?

    @Option(name: .long, help: "Event ID (from --json output) instead of a title")
    var id: String?

    @Option(name: .long, help: "New title")
    var newTitle: String?

    @Option(name: .long, help: "New start date/time")
    var start: String?

    @Option(name: .long, help: "New end date/time")
    var end: String?

    @Flag(name: .long, help: "For a recurring event, also change all later occurrences")
    var future = false

    func validate() throws {
        _ = try EventSelector(title: title, id: id)
    }

    func run() async throws {
        let selector = try EventSelector(title: title, id: id)
        var newStart: Date?
        var newEnd: Date?

        if let startStr = start {
            guard let parsed = Services.dateParser().parse(startStr) else {
                throw CalendarError.invalidDateFormat(startStr)
            }
            newStart = parsed
        }

        if let endStr = end {
            guard let parsed = Services.dateParser().parse(endStr) else {
                throw CalendarError.invalidDateFormat(endStr)
            }
            newEnd = parsed
        }

        if newTitle == nil && newStart == nil && newEnd == nil {
            print("Error: At least one of --new-title, --start, or --end must be specified")
            throw ExitCode.failure
        }

        let service = Services.calendar()
        let updated = try await service.editEvent(
            selector,
            newTitle: newTitle,
            newStart: newStart,
            newEnd: newEnd,
            includeFuture: future
        )

        let scope = future && updated.hasRecurrence ? " and all later occurrences" : ""
        print("Updated event: \(updated.title) (\(DateFormatters.fullDateTime.string(from: updated.startDate)))\(scope)")
        if let t = newTitle {
            print("  New title: \(t)")
        }
        if let s = newStart {
            print("  New start: \(DateFormatters.fullDateTime.string(from: s))")
        }
        if let e = newEnd {
            print("  New end: \(DateFormatters.fullDateTime.string(from: e))")
        }
    }
}
