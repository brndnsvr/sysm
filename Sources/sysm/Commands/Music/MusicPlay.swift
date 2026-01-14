import ArgumentParser

struct MusicPlay: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "play",
        abstract: "Start or resume playback"
    )

    func run() throws {
        let service = MusicService()
        try service.play()
        print("Playing")
    }
}
