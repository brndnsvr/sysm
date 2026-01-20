import ArgumentParser
import Foundation
import SysmCore

struct FocusActivate: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "activate",
        abstract: "Activate a specific focus mode"
    )

    @Argument(help: "Name of the focus mode to activate (e.g., Work, Personal, Sleep)")
    var name: String

    func run() throws {
        let service = Services.focus()

        do {
            try service.activateFocus(name)
            print("Focus mode '\(name)' activated")
        } catch {
            fputs("Error: \(error.localizedDescription)\n", stderr)
            throw ExitCode.failure
        }
    }
}
