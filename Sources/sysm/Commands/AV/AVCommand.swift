import ArgumentParser
import SysmCore

struct AVCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "av",
        abstract: "Audio recording and transcription",
        subcommands: [
            AVDevices.self,
            AVFormats.self,
            AVRecord.self,
            AVTranscribe.self,
        ]
    )
}
