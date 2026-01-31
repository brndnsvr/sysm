import ArgumentParser
import Foundation
import SysmCore

struct ScheduleLogs: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "logs",
        abstract: "View logs for a scheduled job"
    )

    // MARK: - Arguments

    @Argument(help: "Name of the job")
    var name: String

    // MARK: - Options

    @Option(name: .shortAndLong, help: "Number of lines to show (default: 50)")
    var lines: Int = 50

    @Flag(name: .long, help: "Show stderr instead of stdout")
    var stderr: Bool = false

    @Flag(name: .long, help: "Show both stdout and stderr")
    var all: Bool = false

    @Flag(name: .long, help: "Output as JSON")
    var json: Bool = false

    // MARK: - Execution

    func run() throws {
        let service = Services.launchd()
        let (stdout, stderrOut) = try service.getJobLogs(name: name, lines: lines)

        if json {
            let output: [String: String] = [
                "name": name,
                "stdout": stdout,
                "stderr": stderrOut
            ]
            if let data = try? JSONSerialization.data(withJSONObject: output, options: .prettyPrinted),
               let str = String(data: data, encoding: .utf8) {
                print(str)
            }
        } else if all {
            if !stdout.isEmpty {
                print("=== STDOUT ===")
                print(stdout)
            }
            if !stderrOut.isEmpty {
                print("\n=== STDERR ===")
                print(stderrOut)
            }
            if stdout.isEmpty && stderrOut.isEmpty {
                print("No logs found for job: \(name)")
            }
        } else if stderr {
            if stderrOut.isEmpty {
                print("No stderr logs for job: \(name)")
            } else {
                print(stderrOut)
            }
        } else {
            if stdout.isEmpty {
                print("No stdout logs for job: \(name)")
            } else {
                print(stdout)
            }
        }
    }
}
