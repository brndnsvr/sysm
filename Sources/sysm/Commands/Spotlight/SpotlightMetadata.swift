import ArgumentParser
import Foundation

struct SpotlightMetadata: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "metadata",
        abstract: "Show Spotlight metadata for a file"
    )

    @Argument(help: "Path to file")
    var path: String

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.spotlight()
        let metadata = try service.getMetadata(path: path)

        if json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(metadata)
            print(String(data: data, encoding: .utf8)!)
        } else {
            print(metadata.formatted())
        }
    }
}
