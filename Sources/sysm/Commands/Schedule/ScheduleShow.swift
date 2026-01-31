import ArgumentParser
import Foundation
import SysmCore

struct ScheduleShow: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "show",
        abstract: "Show details of a scheduled job"
    )

    // MARK: - Arguments

    @Argument(help: "Name of the job to show")
    var name: String

    // MARK: - Options

    @Flag(name: .long, help: "Output as JSON")
    var json: Bool = false

    // MARK: - Execution

    func run() throws {
        let service = Services.launchd()
        let job = try service.getJob(name: name)

        if json {
            try OutputFormatter.printJSON(job)
        } else {
            print("Job: \(job.name)")
            print("Label: \(job.label)")
            print("Status: \(job.enabled ? "enabled" : "disabled")")

            if let schedule = job.schedule {
                if let interval = schedule.interval {
                    print("Schedule: every \(interval) seconds")
                } else {
                    print("Schedule: \(schedule.cronExpression)")
                }
            }

            print("Command: \(job.command)")

            if job.runAtLoad {
                print("Run at load: yes")
            }

            if let workDir = job.workingDirectory {
                print("Working directory: \(workDir)")
            }

            if let stdout = job.standardOutPath {
                print("Stdout log: \(stdout)")
            }
            if let stderr = job.standardErrorPath {
                print("Stderr log: \(stderr)")
            }

            if let env = job.environmentVariables, !env.isEmpty {
                print("Environment:")
                for (key, value) in env {
                    print("  \(key)=\(value)")
                }
            }

            print("Plist: \(job.plistPath)")
        }
    }
}
