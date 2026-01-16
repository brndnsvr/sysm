import ArgumentParser
import Foundation

struct RemindersTracked: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "tracked",
        abstract: "List all tracked reminders"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let cache = CacheService()
        let tracked = cache.getTrackedReminders()

        if json {
            let output = tracked.map { (key, reminder) in
                [
                    "name": reminder.originalName,
                    "added": reminder.firstSeen,
                    "project": reminder.project,
                    "status": reminder.status
                ]
            }
            try OutputFormatter.printJSON(output)
        } else {
            if tracked.isEmpty {
                print("No tracked reminders")
            } else {
                print("Tracked Reminders:")
                for (_, reminder) in tracked {
                    let project = reminder.project.isEmpty ? "" : " [\(reminder.project)]"
                    let status = reminder.status == "done" ? " ✓" : ""
                    print("  - \(reminder.originalName)\(project)\(status) (added: \(reminder.firstSeen))")
                }
            }
        }
    }
}
