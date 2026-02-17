import ArgumentParser
import Foundation
import SysmCore

struct TimeMachineBackups: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "backups",
        abstract: "List Time Machine backups"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.timeMachine()
        let backups = try service.listBackups()

        if json {
            try OutputFormatter.printJSON(backups)
        } else {
            if backups.isEmpty {
                print("No backups found")
            } else {
                print("Time Machine Backups (\(backups.count)):\n")
                for backup in backups {
                    print("  \(backup.date)")
                    print("    \(backup.path)")
                }
            }
        }
    }
}
