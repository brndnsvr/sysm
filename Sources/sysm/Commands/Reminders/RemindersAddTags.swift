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

    @Flag(name: .long, help: "Use native Reminders tags (visible in Reminders.app)")
    var native = false

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        if native {
            try runNative()
        } else {
            try await runHashtag()
        }
    }

    private func runNative() throws {
        let nativeTagService = Services.nativeTag()

        let backupPath = try nativeTagService.backupDatabase()
        if !json {
            print("Database backed up to: \(backupPath)")
        }

        var added: [String] = []
        var skipped: [String] = []

        for tag in tags {
            let wasAdded = try nativeTagService.addTag(tag, toReminder: id)
            if wasAdded {
                added.append(tag)
            } else {
                skipped.append(tag)
            }
        }

        if json {
            struct NativeAddResult: Codable {
                let reminderId: String
                let added: [String]
                let skipped: [String]
                let backupPath: String
            }
            try OutputFormatter.printJSON(NativeAddResult(
                reminderId: id, added: added, skipped: skipped, backupPath: backupPath
            ))
        } else {
            if !added.isEmpty {
                print("Added native tags:")
                for tag in added { print("  #\(tag)") }
            }
            if !skipped.isEmpty {
                print("Already present:")
                for tag in skipped { print("  #\(tag)") }
            }
        }
    }

    private func runHashtag() async throws {
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
