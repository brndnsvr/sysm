import ArgumentParser
import Foundation
import SysmCore

struct AISummarize: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "summarize",
        abstract: "Summarize a text file"
    )

    @Argument(help: "Text file path")
    var file: String

    @Option(name: .shortAndLong, help: "Save summary to file")
    var output: String?

    @Option(name: .long, help: "Chunk size in characters for large files (default: 4000)")
    var chunkSize: Int?

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        guard FileManager.default.fileExists(atPath: file) else {
            throw FoundationModelsError.fileNotFound(file)
        }

        let text = try String(contentsOfFile: file, encoding: .utf8)
        let service = Services.foundationModels()

        if !json {
            print("Summarizing \(file)...")
        }

        let result = try await service.summarize(text: text, chunkSize: chunkSize)

        if let output = output {
            try result.summary.write(toFile: output, atomically: true, encoding: .utf8)
            if !json {
                print("Saved to \(output)")
            }
        }

        if json {
            try OutputFormatter.printJSON(result)
        } else {
            print("\nSummary (\(result.wordCount) words):\n")
            print(result.summary)
        }
    }
}
