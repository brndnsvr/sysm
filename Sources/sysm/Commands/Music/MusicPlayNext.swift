import ArgumentParser
import Foundation
import SysmCore

struct MusicPlayNext: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "play-next",
        abstract: "Add a track to play next in the queue"
    )

    @Argument(help: "Search query to find and queue a track")
    var query: String

    func run() throws {
        let service = Services.music()

        do {
            try service.playNext(query)
            print("Queued to play next: \(query)")
        } catch {
            fputs("Error: \(error.localizedDescription)\n", stderr)
            throw ExitCode.failure
        }
    }
}
