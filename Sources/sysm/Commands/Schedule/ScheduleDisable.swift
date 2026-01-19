import ArgumentParser
import Foundation
import SysmCore

struct ScheduleDisable: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "disable",
        abstract: "Disable a scheduled job"
    )

    // MARK: - Arguments

    @Argument(help: "Name of the job to disable")
    var name: String

    // MARK: - Execution

    func run() throws {
        let service = LaunchdService()
        try service.disableJob(name: name)
        print("Disabled scheduled job: \(name)")
    }
}
