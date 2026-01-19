import ArgumentParser
import SysmCore

struct MusicPlay: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "play",
        abstract: "Start or resume playback"
    )

    func run() throws {
        let service = Services.music()
        try service.play()
        print("Playing")
    }
}
