import ArgumentParser
import Foundation

struct CalendarDelete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a calendar event"
    )

    @Argument(help: "Event title to delete")
    var title: String

    func run() async throws {
        let service = Services.calendar()
        let success = try await service.deleteEvent(title: title)

        if success {
            print("Deleted event: \(title)")
        } else {
            print("Event '\(title)' not found")
            throw ExitCode.failure
        }
    }
}
