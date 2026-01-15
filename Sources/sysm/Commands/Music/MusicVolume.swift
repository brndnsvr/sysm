import ArgumentParser

struct MusicVolume: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "volume",
        abstract: "Set playback volume (0-100)"
    )

    @Argument(help: "Volume level (0-100)")
    var level: Int

    func run() throws {
        let service = Services.music()
        try service.setVolume(level)
        print("Volume set to \(level)%")
    }
}
