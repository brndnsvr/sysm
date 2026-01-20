import ArgumentParser
import Foundation
import SysmCore

struct MusicRepeat: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "repeat",
        abstract: "Get or set repeat mode"
    )

    @Argument(help: "Set repeat mode: off/one/all (omit to show current state)")
    var mode: String?

    func run() throws {
        let service = Services.music()

        if let mode = mode {
            let repeatMode: RepeatMode
            switch mode.lowercased() {
            case "off", "none", "0":
                repeatMode = .off
            case "one", "single", "1", "track":
                repeatMode = .one
            case "all", "playlist", "2":
                repeatMode = .all
            default:
                fputs("Invalid mode. Use 'off', 'one', or 'all'\n", stderr)
                throw ExitCode.failure
            }
            try service.setRepeatMode(repeatMode)
            print("Repeat: \(repeatMode.rawValue.capitalized)")
        } else {
            let currentMode = try service.getRepeatMode()
            print("Repeat: \(currentMode.rawValue.capitalized)")
        }
    }
}
