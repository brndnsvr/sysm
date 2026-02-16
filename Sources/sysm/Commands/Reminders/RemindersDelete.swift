import ArgumentParser
import Foundation
import SysmCore

struct RemindersDelete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a reminder"
    )

    @Argument(help: "Reminder ID (use 'sysm reminders list --json' to find IDs)")
    var id: String

    @Flag(name: .shortAndLong, help: "Skip confirmation")
    var force = false

    func run() async throws {
        let service = Services.reminders()

        if !force {
            guard await CLI.confirm("Are you sure you want to delete this reminder? [y/N] ") else { return }
        }

        do {
            let success = try await service.deleteReminder(id: id)
            if success {
                print("Reminder deleted")
            } else {
                fputs("Reminder not found\n", stderr)
                throw ExitCode.failure
            }
        } catch {
            fputs("Error: \(error.localizedDescription)\n", stderr)
            throw ExitCode.failure
        }
    }
}
