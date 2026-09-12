import ArgumentParser
import Foundation
import SysmCore

struct CalendarDelete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a calendar event",
        discussion: """
        A recurring event's occurrences share one title and ID. The next \
        occurrence that has not ended is deleted; add --future to delete it \
        and every later occurrence.
        """
    )

    @Argument(help: "Exact title of the event to delete")
    var title: String?

    @Option(name: .long, help: "Event ID (from --json output) instead of a title")
    var id: String?

    @Flag(name: .long, help: "For a recurring event, also delete all later occurrences")
    var future = false

    @Flag(name: .shortAndLong, help: "Skip confirmation")
    var force = false

    func validate() throws {
        _ = try EventSelector(title: title, id: id)
    }

    func run() async throws {
        let service = Services.calendar()
        let selector = try EventSelector(title: title, id: id)

        if !force {
            let event = try await service.findEvent(selector)
            let when = DateFormatters.fullDateTime.string(from: event.startDate)
            let scope = future && event.hasRecurrence ? " and all later occurrences" : ""
            guard await CLI.confirm("Delete '\(event.title)' on \(when)\(scope)? [y/N] ") else { return }
        }

        let deleted = try await service.deleteEvent(selector, includeFuture: future)
        let when = DateFormatters.fullDateTime.string(from: deleted.startDate)
        let scope = future && deleted.hasRecurrence ? " and all later occurrences" : ""
        print("Deleted event: \(deleted.title) (\(when))\(scope)")
    }
}

extension EventSelector {
    /// Builds the selector for a command that takes a title argument or `--id`.
    init(title: String?, id: String?) throws {
        switch (title, id) {
        case (let title?, nil):
            self = .title(title)
        case (nil, let id?):
            self = .id(id)
        case (nil, nil):
            throw ValidationError("Specify an event title or --id")
        case (.some, .some):
            throw ValidationError("Specify an event title or --id, not both")
        }
    }
}
