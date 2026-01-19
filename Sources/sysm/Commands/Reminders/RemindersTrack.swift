import ArgumentParser
import Foundation
import SysmCore

struct RemindersTrack: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "track",
        abstract: "Mark a reminder as tracked"
    )

    @Argument(help: "Reminder name")
    var name: String

    @Option(name: .shortAndLong, help: "Project name to link")
    var project: String?

    func run() async throws {
        let cache = CacheService()
        try cache.trackReminder(name: name, project: project)

        var msg = "Tracking: \(name)"
        if let proj = project {
            msg += " (project: \(proj))"
        }
        print(msg)
    }
}
