import ArgumentParser
import Foundation
import SysmCore

struct AIExtractActions: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "extract-actions",
        abstract: "Extract action items from a text file"
    )

    @Argument(help: "Text file path")
    var file: String

    @Option(name: .shortAndLong, help: "Save action items to file")
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
            print("Extracting action items from \(file)...")
        }

        let result = try await service.extractActionItems(text: text, chunkSize: chunkSize)

        if let output = output {
            var content = ""
            for (i, item) in result.items.enumerated() {
                content += "\(i + 1). \(item.action)"
                if let owner = item.owner { content += " [@\(owner)]" }
                if let priority = item.priority { content += " [\(priority)]" }
                content += "\n"
            }
            try content.write(toFile: output, atomically: true, encoding: .utf8)
            if !json {
                print("Saved to \(output)")
            }
        }

        if json {
            try OutputFormatter.printJSON(result)
        } else {
            if result.items.isEmpty {
                print("\nNo action items found.")
            } else {
                print("\nAction Items (\(result.items.count)):\n")
                for (i, item) in result.items.enumerated() {
                    var line = "  \(i + 1). \(item.action)"
                    if let owner = item.owner { line += " — \(owner)" }
                    if let priority = item.priority { line += " [\(priority)]" }
                    print(line)
                }
            }
        }
    }
}
