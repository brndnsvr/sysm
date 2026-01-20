import ArgumentParser
import Foundation
import SysmCore

struct MusicShuffle: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "shuffle",
        abstract: "Get or set shuffle mode"
    )

    @Argument(help: "Set shuffle: on/off (omit to show current state)")
    var state: String?

    func run() throws {
        let service = Services.music()

        if let state = state {
            let enabled: Bool
            switch state.lowercased() {
            case "on", "true", "1", "yes":
                enabled = true
            case "off", "false", "0", "no":
                enabled = false
            default:
                fputs("Invalid state. Use 'on' or 'off'\n", stderr)
                throw ExitCode.failure
            }
            try service.setShuffle(enabled)
            print("Shuffle: \(enabled ? "On" : "Off")")
        } else {
            let isShuffled = try service.getShuffle()
            print("Shuffle: \(isShuffled ? "On" : "Off")")
        }
    }
}
