import ArgumentParser
import Foundation
import SysmCore

struct SpeakSave: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "save",
        abstract: "Save spoken text to an audio file"
    )

    @Argument(help: "Text to speak")
    var text: String

    @Option(name: .shortAndLong, help: "Output file path (.aiff)")
    var output: String

    @Option(name: .long, help: "Voice name")
    var voice: String?

    @Option(name: .long, help: "Speech rate (words per minute)")
    var rate: Float?

    func run() throws {
        let service = Services.speech()
        try service.save(text: text, voice: voice, rate: rate, outputPath: output)
        print("Saved to: \(output)")
    }
}
