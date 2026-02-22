import ArgumentParser
import Foundation
import SysmCore

struct RemindersMigrateTags: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "migrate-tags",
        abstract: "Migrate hashtag-in-notes tags to native Reminders tags"
    )

    @Flag(name: .long, help: "Show migration plan without making changes")
    var dryRun = false

    @Flag(name: .long, help: "Remove hashtags from notes after migration")
    var cleanNotes = false

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let reminderService = Services.reminders()
        let nativeTagService = Services.nativeTag()

        do {
            // Get all reminders with their notes
            let reminders = try await reminderService.getReminders(listName: nil, includeCompleted: true)
            let tagged = reminders.filter { !$0.tags.isEmpty }

            if tagged.isEmpty {
                if json {
                    struct EmptyResult: Codable {
                        let message: String
                        let remindersProcessed: Int
                    }
                    try OutputFormatter.printJSON(EmptyResult(
                        message: "No reminders with hashtag tags found",
                        remindersProcessed: 0
                    ))
                } else {
                    print("No reminders with hashtag tags found")
                }
                return
            }

            if dryRun {
                try printDryRun(tagged)
                return
            }

            // Backup before writing
            let backupPath = try nativeTagService.backupDatabase()
            if !json {
                print("Database backed up to: \(backupPath)")
                print("")
            }

            var totalAdded = 0
            var totalSkipped = 0
            var totalReminders = 0
            var results: [MigrationResult] = []

            for reminder in tagged {
                var added: [String] = []
                var skipped: [String] = []

                for tag in reminder.tags {
                    do {
                        let wasAdded = try nativeTagService.addTag(tag, toReminder: reminder.id)
                        if wasAdded {
                            added.append(tag)
                            totalAdded += 1
                        } else {
                            skipped.append(tag)
                            totalSkipped += 1
                        }
                    } catch {
                        if !json {
                            fputs("  Warning: Failed to add tag '\(tag)' to '\(reminder.title)': \(error.localizedDescription)\n", stderr)
                        }
                        skipped.append(tag)
                        totalSkipped += 1
                    }
                }

                totalReminders += 1

                if !json && (!added.isEmpty || !skipped.isEmpty) {
                    print("[\(totalReminders)/\(tagged.count)] \(reminder.title)")
                    if !added.isEmpty { print("  Added: \(added.map { "#\($0)" }.joined(separator: " "))") }
                    if !skipped.isEmpty { print("  Skipped: \(skipped.map { "#\($0)" }.joined(separator: " "))") }
                }

                results.append(MigrationResult(
                    reminderId: reminder.id,
                    title: reminder.title,
                    added: added,
                    skipped: skipped
                ))

                // Clean notes if requested
                if cleanNotes && !added.isEmpty {
                    var updatedNotes = reminder.notes
                    for tag in added {
                        updatedNotes = TagHelper.removeTag(tag, from: updatedNotes)
                    }
                    _ = try await reminderService.editReminder(
                        id: reminder.id,
                        newTitle: nil,
                        newStartDate: nil,
                        newDueDate: nil,
                        newPriority: nil,
                        newNotes: updatedNotes,
                        newAlarms: nil
                    )
                }
            }

            if json {
                struct MigrationOutput: Codable {
                    let remindersProcessed: Int
                    let tagsAdded: Int
                    let tagsSkipped: Int
                    let cleanedNotes: Bool
                    let backupPath: String
                    let results: [MigrationResult]
                }
                try OutputFormatter.printJSON(MigrationOutput(
                    remindersProcessed: totalReminders,
                    tagsAdded: totalAdded,
                    tagsSkipped: totalSkipped,
                    cleanedNotes: cleanNotes,
                    backupPath: backupPath,
                    results: results
                ))
            } else {
                print("")
                print("Migration complete:")
                print("  Reminders processed: \(totalReminders)")
                print("  Tags added: \(totalAdded)")
                print("  Tags skipped: \(totalSkipped)")
                if cleanNotes {
                    print("  Notes cleaned: yes")
                }
            }
        } catch {
            fputs("Error: \(error.localizedDescription)\n", stderr)
            throw ExitCode.failure
        }
    }

    private func printDryRun(_ tagged: [Reminder]) throws {
        if json {
            struct DryRunOutput: Codable {
                struct Plan: Codable {
                    let reminderId: String
                    let title: String
                    let tags: [String]
                }
                let dryRun: Bool
                let remindersToMigrate: Int
                let totalTags: Int
                let plan: [Plan]
            }

            let plans = tagged.map { r in
                DryRunOutput.Plan(reminderId: r.id, title: r.title, tags: r.tags)
            }
            let totalTags = tagged.reduce(0) { $0 + $1.tags.count }
            try OutputFormatter.printJSON(DryRunOutput(
                dryRun: true,
                remindersToMigrate: tagged.count,
                totalTags: totalTags,
                plan: plans
            ))
        } else {
            let totalTags = tagged.reduce(0) { $0 + $1.tags.count }
            print("Dry run — no changes will be made\n")
            print("Reminders to migrate: \(tagged.count)")
            print("Total tags to create: \(totalTags)\n")

            for reminder in tagged {
                print("  \(reminder.title)")
                print("    Tags: \(reminder.tags.map { "#\($0)" }.joined(separator: " "))")
            }

            print("\nRun without --dry-run to apply changes.")
        }
    }
}

private struct MigrationResult: Codable {
    let reminderId: String
    let title: String
    let added: [String]
    let skipped: [String]
}
