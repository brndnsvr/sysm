import ArgumentParser
import Foundation

struct RemindersUntrack: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "untrack",
        abstract: "Remove a reminder from tracking"
    )

    @Argument(help: "Reminder name")
    var name: String

    func run() async throws {
        let cache = CacheService()
        let removed = try cache.untrackReminder(name: name)

        if removed {
            print("Untracked: \(name)")
        } else {
            fputs("Not found: \(name)\n", stderr)
            throw ExitCode.failure
        }
    }
}
