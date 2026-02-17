import ArgumentParser
import Foundation
import SysmCore

struct ImageThumbnail: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "thumbnail",
        abstract: "Generate a thumbnail"
    )

    @Argument(help: "Input image path")
    var input: String

    @Option(name: .shortAndLong, help: "Output path")
    var output: String

    @Option(name: .shortAndLong, help: "Maximum dimension in pixels")
    var size: Int = 256

    func run() throws {
        let service = Services.image()
        try service.thumbnail(inputPath: input, outputPath: output, size: size)
        print("Thumbnail saved to: \((output as NSString).expandingTildeInPath)")
    }
}
