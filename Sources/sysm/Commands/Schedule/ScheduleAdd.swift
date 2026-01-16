import ArgumentParser
import Foundation

struct ScheduleAdd: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "add",
        abstract: "Create a new scheduled job"
    )

    // MARK: - Arguments

    @Argument(help: "Name for the scheduled job")
    var name: String

    // MARK: - Options

    @Option(name: .long, help: "Command to execute")
    var cmd: String

    @Option(name: .long, help: "Cron schedule (M H D Mo W)")
    var cron: String?

    @Option(name: .long, help: "Run every N seconds")
    var every: Int?

    @Option(name: .long, help: "Working directory for the job")
    var workdir: String?

    @Flag(name: .long, help: "Also run immediately when created")
    var runAtLoad: Bool = false

    @Flag(name: .long, help: "Overwrite existing job")
    var force: Bool = false

    @Flag(name: .long, help: "Output as JSON")
    var json: Bool = false

    // MARK: - Validation

    func validate() throws {
        if cron == nil && every == nil {
            throw ValidationError("Provide --cron or --every to specify when to run")
        }
        if cron != nil && every != nil {
            throw ValidationError("Use either --cron or --every, not both")
        }
    }

    // MARK: - Execution

    func run() throws {
        let service = LaunchdService()

        let job = try service.createJob(
            name: name,
            command: cmd,
            cron: cron,
            interval: every,
            runAtLoad: runAtLoad,
            workingDirectory: workdir,
            force: force
        )

        if json {
            try OutputFormatter.printJSON(job)
        } else {
            print("Created scheduled job: \(job.name)")
            print("Label: \(job.label)")
            if let schedule = job.schedule {
                if let interval = schedule.interval {
                    print("Schedule: every \(interval) seconds")
                } else {
                    print("Schedule: \(schedule.cronExpression)")
                }
            }
            print("Command: \(job.command)")
            print("Logs: \(job.standardOutPath ?? "~/.sysm/logs/\(name).log")")
            print("\nManage with:")
            print("  sysm schedule show \(name)")
            print("  sysm schedule logs \(name)")
            print("  sysm schedule remove \(name)")
        }
    }
}
