import ArgumentParser
import Foundation
import SysmCore

struct RemindersAddTags: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "add-tags",
        abstract: "Add tags to a reminder (uses #hashtag format in notes)"
    )

    @Argument(help: "Reminder ID")
    var id: String

    @Argument(help: "Tags to add (space-separated)")
    var tags: [String]

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let service = Services.reminders()

        do {
            let reminders = try await service.getReminders(listName: nil, includeCompleted: true)
            guard let currentReminder = reminders.first(where: { $0.id == id }) else {
                fputs("Error: Reminder not found\n", stderr)
                throw ExitCode.failure
            }

            let updatedNotes = TagHelper.addTags(tags, to: currentReminder.notes)

            let reminder = try await service.editReminder(
                id: id,
                newTitle: nil,
                newStartDate: nil,
                newDueDate: nil,
                newPriority: nil,
                newNotes: updatedNotes,
                newAlarms: nil
            )

            if json {
                try OutputFormatter.printJSON(reminder)
            } else {
                print("Added tags to '\(reminder.title)':")
                for tag in tags {
                    print("  #\(tag.lowercased())")
                }
                print("\nAll tags: \(reminder.tags.map { "#\($0)" }.joined(separator: " "))")
            }
        } catch {
            fputs("Error: \(error.localizedDescription)\n", stderr)
            throw ExitCode.failure
        }
    }
}
