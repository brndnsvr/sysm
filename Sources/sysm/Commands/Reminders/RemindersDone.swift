import ArgumentParser
import Foundation

struct RemindersDone: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "done",
        abstract: "Mark a tracked reminder as done"
    )

    @Argument(help: "Reminder name")
    var name: String

    func run() async throws {
        let cache = CacheService()
        let completed = try cache.completeTracked(name: name)

        if completed {
            print("Done: \(name)")
        } else {
            fputs("Not found or not tracked: \(name)\n", stderr)
            throw ExitCode.failure
        }
    }
}
