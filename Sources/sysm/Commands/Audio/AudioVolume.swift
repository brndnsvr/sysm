import ArgumentParser
import Foundation
import SysmCore

struct AudioVolume: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "volume",
        abstract: "Show or set system volume",
        subcommands: [
            AudioVolumeSet.self,
        ],
        defaultSubcommand: nil
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.audio()
        let info = try service.getVolume()

        if json {
            try OutputFormatter.printJSON(info)
        } else {
            print("Volume: \(info.volume)%")
            print("Muted: \(info.isMuted ? "Yes" : "No")")
        }
    }
}

struct AudioVolumeSet: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "set",
        abstract: "Set system volume (0-100)"
    )

    @Argument(help: "Volume level (0-100)")
    var level: Int

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.audio()
        try service.setVolume(level)

        if json {
            try OutputFormatter.printJSON(["status": "set", "volume": "\(level)"])
        } else {
            print("Volume set to \(level)%")
        }
    }
}
