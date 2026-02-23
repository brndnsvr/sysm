import ArgumentParser
import SysmCore

struct AudioUnmute: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "unmute",
        abstract: "Unmute system audio"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.audio()
        try service.unmute()

        if json {
            try OutputFormatter.printJSON(["status": "unmuted"])
        } else {
            print("Audio unmuted")
        }
    }
}
