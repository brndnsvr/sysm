import ArgumentParser
import Foundation
import SysmCore

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
            try OutputFormatter.printJSON(metadata)
        } else {
            print(metadata.formatted())
        }
    }
}
