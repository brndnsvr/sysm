import ArgumentParser
import Foundation
import SysmCore

struct ScheduleRemove: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "remove",
        abstract: "Remove a scheduled job"
    )

    // MARK: - Arguments

    @Argument(help: "Name of the job to remove")
    var name: String

    // MARK: - Options

    @Flag(name: .long, help: "Skip confirmation")
    var force: Bool = false

    // MARK: - Execution

    func run() throws {
        let service = LaunchdService()

        // Verify job exists first
        _ = try service.getJob(name: name)

        try service.removeJob(name: name)
        print("Removed scheduled job: \(name)")
    }
}
