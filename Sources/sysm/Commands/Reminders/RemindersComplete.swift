import ArgumentParser
import Foundation
import SysmCore

struct RemindersComplete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "complete",
        abstract: "Mark a reminder as complete"
    )

    @Argument(help: "Exact title of an incomplete reminder")
    var name: String?

    @Option(name: .long, help: "Reminder ID (from --json output) instead of a title")
    var id: String?

    func validate() throws {
        _ = try ReminderSelector(title: name, id: id)
    }

    func run() async throws {
        let service = Services.reminders()
        let reminder = try await service.completeReminder(try ReminderSelector(title: name, id: id))
        print("Completed: \(reminder.title) [\(reminder.listName)]")
    }
}

extension ReminderSelector {
    /// Builds the selector for a command that takes a title argument or `--id`.
    init(title: String?, id: String?) throws {
        switch (title, id) {
        case (let title?, nil):
            self = .title(title)
        case (nil, let id?):
            self = .id(id)
        case (nil, nil):
            throw ValidationError("Specify a reminder title or --id")
        case (.some, .some):
            throw ValidationError("Specify a reminder title or --id, not both")
        }
    }
}
