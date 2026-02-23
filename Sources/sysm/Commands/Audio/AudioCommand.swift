import ArgumentParser
import SysmCore

struct AudioCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "audio",
        abstract: "System audio control",
        subcommands: [
            AudioVolume.self,
            AudioMute.self,
            AudioUnmute.self,
            AudioDevices.self,
            AudioInput.self,
            AudioOutput.self,
        ]
    )
}
