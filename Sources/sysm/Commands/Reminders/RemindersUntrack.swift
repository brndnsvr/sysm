import ArgumentParser
import Foundation
import SysmCore

struct RemindersUntrack: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "untrack",
        abstract: "Remove a reminder from tracking"
    )

    @Argument(help: "Reminder name")
    var name: String

    func run() async throws {
        let cache = Services.cache()
        let removed = try cache.untrackReminder(name: name)

        if removed {
            print("Untracked: \(name)")
        } else {
            fputs("Not found: \(name)\n", stderr)
            throw ExitCode.failure
        }
    }
}
