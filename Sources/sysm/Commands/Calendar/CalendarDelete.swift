import ArgumentParser
import Foundation
import SysmCore

struct CalendarDelete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a calendar event"
    )

    @Argument(help: "Event title to delete")
    var title: String

    @Flag(name: .shortAndLong, help: "Skip confirmation")
    var force = false

    func run() async throws {
        let service = Services.calendar()

        if !force {
            guard await CLI.confirm("Delete event '\(title)'? [y/N] ") else { return }
        }

        let success = try await service.deleteEvent(title: title)

        if success {
            print("Deleted event: \(title)")
        } else {
            print("Event '\(title)' not found")
            throw ExitCode.failure
        }
    }
}
