import ArgumentParser
import SysmCore

struct SpeakCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "speak",
        abstract: "Text-to-speech",
        subcommands: [
            SpeakText.self,
            SpeakVoices.self,
            SpeakSave.self,
        ]
    )
}
