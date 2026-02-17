import ArgumentParser
import Foundation
import SysmCore

struct ImageResize: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "resize",
        abstract: "Resize an image"
    )

    @Argument(help: "Input image path")
    var input: String

    @Option(name: .shortAndLong, help: "Output path")
    var output: String

    @Option(name: .shortAndLong, help: "Target width in pixels")
    var width: Int?

    @Option(name: .long, help: "Target height in pixels")
    var height: Int?

    func run() throws {
        guard width != nil || height != nil else {
            throw ValidationError("Specify at least --width or --height")
        }

        let service = Services.image()
        try service.resize(inputPath: input, outputPath: output, width: width, height: height)
        print("Resized image saved to: \((output as NSString).expandingTildeInPath)")
    }
}
