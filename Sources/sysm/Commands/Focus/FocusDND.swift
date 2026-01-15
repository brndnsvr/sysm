import ArgumentParser
import Foundation

struct FocusDND: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "dnd",
        abstract: "Toggle Do Not Disturb"
    )

    @Argument(help: "on or off")
    var state: String

    func run() throws {
        let service = Services.focus()

        switch state.lowercased() {
        case "on", "enable", "1", "true":
            try service.enableDND()
            print("Do Not Disturb: enabled")

        case "off", "disable", "0", "false":
            try service.disableDND()
            print("Do Not Disturb: disabled")

        default:
            fputs("Error: state must be 'on' or 'off'\n", stderr)
            throw ExitCode.failure
        }
    }
}
