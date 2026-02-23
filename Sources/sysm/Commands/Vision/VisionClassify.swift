import ArgumentParser
import Foundation
import SysmCore

struct VisionClassify: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "classify",
        abstract: "Classify image contents"
    )

    @Argument(help: "Image path")
    var image: String

    @Option(name: .long, help: "Maximum results")
    var limit: Int = 10

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.vision()
        let results = Array(try service.classifyImage(imagePath: image).prefix(limit))

        if json {
            try OutputFormatter.printJSON(results)
        } else {
            if results.isEmpty {
                print("No classifications found")
            } else {
                for result in results {
                    let confidence = String(format: "%.1f%%", result.confidence * 100)
                    print("  \(result.identifier): \(confidence)")
                }
            }
        }
    }
}
