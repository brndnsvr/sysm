import ArgumentParser

struct MusicPause: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "pause",
        abstract: "Pause playback"
    )

    func run() throws {
        let service = MusicService()
        try service.pause()
        print("Paused")
    }
}
