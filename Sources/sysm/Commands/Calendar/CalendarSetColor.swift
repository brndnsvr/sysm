import ArgumentParser
import Foundation
import SysmCore

struct CalendarSetColor: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "set-color",
        abstract: "Set a calendar's color"
    )

    @Argument(help: "Calendar name")
    var name: String

    @Option(name: .long, help: "Hex color (e.g., #FF5733 or FF5733)")
    var color: String

    func run() async throws {
        let service = Services.calendar()
        let success = try await service.setCalendarColor(name: name, hexColor: color)

        if success {
            print("Set color for calendar '\(name)' to \(color)")
        } else {
            print("Failed to set calendar color")
        }
    }
}
