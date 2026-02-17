import ArgumentParser
import Foundation
import SysmCore

struct TimeMachineStatus_: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "status",
        abstract: "Show Time Machine status"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.timeMachine()
        let status = try service.getStatus()

        if json {
            try OutputFormatter.printJSON(status)
        } else {
            print("Time Machine Status:")
            print("  Running: \(status.running ? "Yes" : "No")")
            if let phase = status.phase {
                print("  Phase: \(phase)")
            }
            if let progress = status.progress {
                print("  Progress: \(String(format: "%.1f", progress * 100))%")
            }
            if let dest = status.destination {
                print("  Destination: \(dest)")
            }
        }
    }
}
