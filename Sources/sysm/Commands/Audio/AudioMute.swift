import ArgumentParser
import SysmCore

struct AudioMute: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "mute",
        abstract: "Mute system audio"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.audio()
        try service.mute()

        if json {
            try OutputFormatter.printJSON(["status": "muted"])
        } else {
            print("Audio muted")
        }
    }
}
