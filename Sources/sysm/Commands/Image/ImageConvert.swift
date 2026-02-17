import ArgumentParser
import Foundation
import SysmCore

struct ImageConvert: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "convert",
        abstract: "Convert image format"
    )

    @Argument(help: "Input image path")
    var input: String

    @Option(name: .shortAndLong, help: "Output path")
    var output: String

    @Option(name: .shortAndLong, help: "Output format: png, jpeg, tiff, heif")
    var format: ImageFormat

    func run() throws {
        let service = Services.image()
        try service.convert(inputPath: input, outputPath: output, format: format)
        print("Converted image saved to: \((output as NSString).expandingTildeInPath)")
    }
}

extension ImageFormat: ExpressibleByArgument {}
