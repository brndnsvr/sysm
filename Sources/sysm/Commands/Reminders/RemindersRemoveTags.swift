import ArgumentParser
import Foundation
import SysmCore

struct RemindersRemoveTags: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "remove-tags",
        abstract: "Remove tags from a reminder"
    )

    @Argument(help: "Reminder ID")
    var id: String

    @Argument(help: "Tags to remove (space-separated)")
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

        var removed: [String] = []
        var notFound: [String] = []

        for tag in tags {
            let wasRemoved = try nativeTagService.removeTag(tag, fromReminder: id)
            if wasRemoved {
                removed.append(tag)
            } else {
                notFound.append(tag)
            }
        }

        if json {
            struct NativeRemoveResult: Codable {
                let reminderId: String
                let removed: [String]
                let notFound: [String]
            }
            try OutputFormatter.printJSON(NativeRemoveResult(
                reminderId: id, removed: removed, notFound: notFound
            ))
        } else {
            if !removed.isEmpty {
                print("Removed native tags:")
                for tag in removed { print("  #\(tag)") }
            }
            if !notFound.isEmpty {
                print("Not found:")
                for tag in notFound { print("  #\(tag)") }
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

            var updatedNotes = currentReminder.notes
            for tag in tags {
                updatedNotes = TagHelper.removeTag(tag, from: updatedNotes)
            }

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
                print("Removed tags from '\(reminder.title)':")
                for tag in tags {
                    print("  #\(tag.lowercased())")
                }
                if !reminder.tags.isEmpty {
                    print("\nRemaining tags: \(reminder.tags.map { "#\($0)" }.joined(separator: " "))")
                } else {
                    print("\nNo tags remaining")
                }
            }
        } catch {
            fputs("Error: \(error.localizedDescription)\n", stderr)
            throw ExitCode.failure
        }
    }
}
