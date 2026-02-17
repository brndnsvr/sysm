import ArgumentParser
import Foundation
import SysmCore

struct NotifySchedule: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "schedule",
        abstract: "Schedule a notification for later"
    )

    @Argument(help: "Notification title")
    var title: String

    @Argument(help: "Notification body")
    var body: String

    @Option(name: .long, help: "Date/time to trigger (e.g. '2024-12-25 09:00', 'tomorrow 3pm')")
    var at: String

    @Option(name: .long, help: "Notification subtitle")
    var subtitle: String?

    @Flag(name: .long, help: "Play notification sound")
    var sound = false

    func run() async throws {
        let dateParser = Services.dateParser()
        guard let triggerDate = dateParser.parse(at) else {
            throw ValidationError("Could not parse date: '\(at)'")
        }

        guard triggerDate > Date() else {
            throw ValidationError("Scheduled date must be in the future")
        }

        let service = Services.notification()
        let id = try await service.schedule(
            title: title,
            body: body,
            subtitle: subtitle,
            triggerDate: triggerDate,
            sound: sound
        )

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        print("Notification scheduled for \(formatter.string(from: triggerDate))")
        print("ID: \(id)")
    }
}
