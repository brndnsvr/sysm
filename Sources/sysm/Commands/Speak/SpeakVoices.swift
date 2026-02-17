import ArgumentParser
import Foundation
import SysmCore

struct SpeakVoices: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "voices",
        abstract: "List available voices"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    @Option(name: .long, help: "Filter by language code (e.g., en_US)")
    var language: String?

    func run() throws {
        let service = Services.speech()
        var voices = service.listVoices()

        if let language = language {
            voices = voices.filter { $0.language.lowercased().contains(language.lowercased()) }
        }

        if json {
            try OutputFormatter.printJSON(voices)
        } else {
            if voices.isEmpty {
                print("No voices found")
            } else {
                print("Available voices (\(voices.count)):\n")
                for voice in voices {
                    print("  \(voice.name) [\(voice.language)]")
                }
            }
        }
    }
}
