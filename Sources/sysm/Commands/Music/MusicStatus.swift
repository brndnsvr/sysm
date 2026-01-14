import ArgumentParser
import Foundation

struct MusicStatus: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "status",
        abstract: "Show currently playing track"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = MusicService()
        guard let status = try service.getStatus() else {
            print("No track information available")
            return
        }

        if status.state == "stopped" && status.name.isEmpty {
            print("Music is stopped (no track playing)")
            return
        }

        if json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(status)
            print(String(data: data, encoding: .utf8)!)
        } else {
            print("Now Playing:\n")
            print(status.formatted())
        }
    }
}
