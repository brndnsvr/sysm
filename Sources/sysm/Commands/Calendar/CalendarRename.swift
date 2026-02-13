import ArgumentParser
import Foundation
import SysmCore

struct CalendarRename: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "rename",
        abstract: "Rename a calendar"
    )

    @Argument(help: "Current calendar name")
    var name: String

    @Option(name: .long, help: "New calendar name")
    var newName: String

    func run() async throws {
        let service = Services.calendar()
        let success = try await service.renameCalendar(name: name, newName: newName)

        if success {
            print("Renamed calendar '\(name)' to '\(newName)'")
        } else {
            print("Failed to rename calendar")
        }
    }
}
