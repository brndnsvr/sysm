import ArgumentParser

struct MusicNext: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "next",
        abstract: "Skip to next track"
    )

    func run() throws {
        let service = MusicService()
        try service.nextTrack()
        print("Skipped to next track")
    }
}
