import ArgumentParser
import Foundation
import SysmCore

struct SpeakText: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "text",
        abstract: "Speak text aloud"
    )

    @Argument(help: "Text to speak")
    var text: String

    @Option(name: .long, help: "Voice name (use 'sysm speak voices' to list)")
    var voice: String?

    @Option(name: .long, help: "Speech rate (words per minute, default ~175)")
    var rate: Float?

    func run() throws {
        let service = Services.speech()
        try service.speak(text: text, voice: voice, rate: rate)
    }
}
