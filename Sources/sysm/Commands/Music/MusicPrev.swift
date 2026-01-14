import ArgumentParser

struct MusicPrev: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "prev",
        abstract: "Go to previous track"
    )

    func run() throws {
        let service = MusicService()
        try service.previousTrack()
        print("Went to previous track")
    }
}
