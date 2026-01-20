import ArgumentParser
import Foundation
import SysmCore

struct MusicPlayTrack: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "play-track",
        abstract: "Play a specific track by searching for it"
    )

    @Argument(help: "Search query to find and play a track")
    var query: String

    func run() throws {
        let service = Services.music()

        do {
            try service.playTrack(query)
            print("Playing: \(query)")
        } catch {
            fputs("Error: \(error.localizedDescription)\n", stderr)
            throw ExitCode.failure
        }
    }
}
