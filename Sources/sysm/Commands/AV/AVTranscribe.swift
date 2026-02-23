import ArgumentParser
import Foundation
import SysmCore

struct AVTranscribe: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "transcribe",
        abstract: "Transcribe audio file to text"
    )

    @Argument(help: "Audio file path")
    var file: String

    @Option(name: .shortAndLong, help: "Language code (e.g., en-US, ja-JP)")
    var language: String?

    @Option(name: .shortAndLong, help: "Save transcription to file")
    var output: String?

    @Flag(name: .long, help: "Include timestamps for each segment")
    var timestamps = false

    @Option(name: .long, help: "Chunk duration in seconds for long audio (default: 3300)")
    var chunkDuration: Double?

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let service = Services.av()

        if !json {
            print("Transcribing \(file)...")
        }

        let result = try await service.transcribe(
            filePath: file,
            language: language,
            timestamps: timestamps,
            chunkDuration: chunkDuration
        )

        // Save to file if requested
        if let output = output {
            if timestamps && !result.segments.isEmpty {
                var content = ""
                for segment in result.segments {
                    let time = formatTimestamp(segment.timestamp)
                    content += "[\(time)] \(segment.text)\n"
                }
                try content.write(toFile: output, atomically: true, encoding: .utf8)
            } else {
                try result.text.write(toFile: output, atomically: true, encoding: .utf8)
            }
            if !json {
                print("Saved to \(output)")
            }
        }

        if json {
            try OutputFormatter.printJSON(result)
        } else {
            let dur = String(format: "%.1f", result.duration)
            print("\nTranscription (\(dur)s, \(result.language ?? "auto")):\n")
            if timestamps && !result.segments.isEmpty {
                for segment in result.segments {
                    let time = formatTimestamp(segment.timestamp)
                    print("[\(time)] \(segment.text)")
                }
            } else {
                print(result.text)
            }
        }
    }

    private func formatTimestamp(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
