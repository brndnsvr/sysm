import ArgumentParser
import Foundation
import SysmCore

struct ScheduleRun: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "run",
        abstract: "Manually trigger a scheduled job"
    )

    // MARK: - Arguments

    @Argument(help: "Name of the job to run")
    var name: String

    // MARK: - Execution

    func run() throws {
        let service = Services.launchd()
        try service.runJobNow(name: name)
        print("Triggered job: \(name)")
        print("Check logs with: sysm schedule logs \(name)")
    }
}
