import ArgumentParser
import Foundation
import SysmCore

struct MusicStatus: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "status",
        abstract: "Show currently playing track"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.music()
        let status = try service.getStatus()

        if json {
            let output = status ?? NowPlaying(
                name: "", artist: "", album: "",
                duration: 0, position: 0, state: "stopped"
            )
            try OutputFormatter.printJSON(output)
        } else {
            guard let status else {
                print("No track information available")
                return
            }
            if status.state == "stopped" && status.name.isEmpty {
                print("Music is stopped (no track playing)")
                return
            }
            print("Now Playing:\n")
            print(status.formatted())
        }
    }
}
