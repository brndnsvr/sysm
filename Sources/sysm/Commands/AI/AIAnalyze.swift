import ArgumentParser
import Foundation
import SysmCore

struct AIAnalyze: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "analyze",
        abstract: "Analyze a text file with a custom prompt"
    )

    @Argument(help: "Text file path")
    var file: String

    @Option(name: .shortAndLong, help: "Analysis prompt (what to look for)")
    var prompt: String = "Provide a detailed analysis of this text"

    @Option(name: .shortAndLong, help: "Save analysis to file")
    var output: String?

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        guard FileManager.default.fileExists(atPath: file) else {
            throw FoundationModelsError.fileNotFound(file)
        }

        let text = try String(contentsOfFile: file, encoding: .utf8)
        let service = Services.foundationModels()

        if !json {
            print("Analyzing \(file)...")
        }

        let result = try await service.analyze(text: text, prompt: prompt)

        if let output = output {
            try result.analysis.write(toFile: output, atomically: true, encoding: .utf8)
            if !json {
                print("Saved to \(output)")
            }
        }

        if json {
            try OutputFormatter.printJSON(result)
        } else {
            print("\nAnalysis:\n")
            print(result.analysis)
        }
    }
}
