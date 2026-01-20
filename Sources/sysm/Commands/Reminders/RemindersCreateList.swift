import ArgumentParser
import Foundation
import SysmCore

struct RemindersCreateList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create-list",
        abstract: "Create a new reminder list"
    )

    @Argument(help: "Name for the new list")
    var name: String

    func run() async throws {
        let service = Services.reminders()

        do {
            let success = try await service.createList(name: name)
            if success {
                print("Created list: \(name)")
            }
        } catch {
            fputs("Error: \(error.localizedDescription)\n", stderr)
            throw ExitCode.failure
        }
    }
}
