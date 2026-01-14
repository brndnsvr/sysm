import ArgumentParser
import Foundation

struct ScheduleList: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List all scheduled jobs"
    )

    // MARK: - Options

    @Flag(name: .long, help: "Output as JSON")
    var json: Bool = false

    @Flag(name: .shortAndLong, help: "Show detailed information")
    var verbose: Bool = false

    // MARK: - Execution

    func run() throws {
        let service = LaunchdService()
        let jobs = try service.listJobs()

        if jobs.isEmpty {
            if json {
                print("[]")
            } else {
                print("No scheduled jobs found")
                print("\nCreate one with: sysm schedule add <name> --cron \"...\" --cmd \"...\"")
            }
            return
        }

        if json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(jobs)
            print(String(data: data, encoding: .utf8)!)
        } else {
            print("Scheduled Jobs (\(jobs.count)):\n")
            for job in jobs {
                let status = job.enabled ? "enabled" : "disabled"
                print("  \(job.name) [\(status)]")

                if let schedule = job.schedule {
                    if let interval = schedule.interval {
                        print("    Schedule: every \(formatInterval(interval))")
                    } else {
                        print("    Schedule: \(schedule.cronExpression)")
                    }
                }

                if verbose {
                    print("    Command: \(job.command)")
                    print("    Plist: \(job.plistPath)")
                    if let logPath = job.standardOutPath {
                        print("    Logs: \(logPath)")
                    }
                }
                print("")
            }
        }
    }

    private func formatInterval(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds) seconds"
        } else if seconds < 3600 {
            return "\(seconds / 60) minutes"
        } else if seconds < 86400 {
            return "\(seconds / 3600) hours"
        } else {
            return "\(seconds / 86400) days"
        }
    }
}
