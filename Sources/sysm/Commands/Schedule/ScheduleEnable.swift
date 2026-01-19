import ArgumentParser
import Foundation
import SysmCore

struct ScheduleEnable: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "enable",
        abstract: "Enable a scheduled job"
    )

    // MARK: - Arguments

    @Argument(help: "Name of the job to enable")
    var name: String

    // MARK: - Execution

    func run() throws {
        let service = LaunchdService()
        try service.enableJob(name: name)
        print("Enabled scheduled job: \(name)")
    }
}
