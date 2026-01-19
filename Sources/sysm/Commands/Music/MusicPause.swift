import ArgumentParser
import SysmCore

struct MusicPause: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "pause",
        abstract: "Pause playback"
    )

    func run() throws {
        let service = Services.music()
        try service.pause()
        print("Paused")
    }
}
