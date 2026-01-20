import ArgumentParser
import Foundation
import SysmCore

struct RemindersDeleteList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete-list",
        abstract: "Delete a reminder list (and all its reminders)"
    )

    @Argument(help: "Name of the list to delete")
    var name: String

    @Flag(name: .shortAndLong, help: "Skip confirmation")
    var force = false

    func run() async throws {
        let service = Services.reminders()

        if !force {
            print("WARNING: This will delete the list '\(name)' and ALL its reminders.")
            print("Are you sure? (y/N) ", terminator: "")
            guard let response = readLine()?.lowercased(), response == "y" || response == "yes" else {
                print("Cancelled")
                return
            }
        }

        do {
            let success = try await service.deleteList(name: name)
            if success {
                print("Deleted list: \(name)")
            }
        } catch {
            fputs("Error: \(error.localizedDescription)\n", stderr)
            throw ExitCode.failure
        }
    }
}
