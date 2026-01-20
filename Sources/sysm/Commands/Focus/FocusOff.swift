import ArgumentParser
import Foundation
import SysmCore

struct FocusOff: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "off",
        abstract: "Turn off the current focus mode"
    )

    func run() throws {
        let service = Services.focus()

        do {
            try service.deactivateFocus()
            print("Focus mode deactivated")
        } catch {
            fputs("Error: \(error.localizedDescription)\n", stderr)
            throw ExitCode.failure
        }
    }
}
