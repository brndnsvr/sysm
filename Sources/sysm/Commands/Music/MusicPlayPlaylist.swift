import ArgumentParser
import Foundation
import SysmCore

struct MusicPlayPlaylist: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "play-playlist",
        abstract: "Play a specific playlist"
    )

    @Argument(help: "Name of the playlist to play")
    var name: String

    func run() throws {
        let service = Services.music()

        do {
            try service.playPlaylist(name)
            print("Playing playlist: \(name)")
        } catch {
            fputs("Error: \(error.localizedDescription)\n", stderr)
            throw ExitCode.failure
        }
    }
}
