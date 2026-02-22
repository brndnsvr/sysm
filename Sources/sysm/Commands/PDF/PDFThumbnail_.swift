import ArgumentParser
import Foundation
import SysmCore

struct PDFThumbnail_: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "thumbnail",
        abstract: "Render a PDF page as a PNG image"
    )

    @Argument(help: "PDF file path")
    var input: String

    @Option(name: .long, help: "Page number (1-based)")
    var page: Int

    @Option(name: .shortAndLong, help: "Output PNG path")
    var output: String

    @Option(name: .shortAndLong, help: "Maximum dimension in pixels")
    var size: Int = 256

    func run() throws {
        let service = Services.pdf()
        try service.thumbnail(path: input, page: page, outputPath: output, size: size)
        print("Thumbnail saved to: \((output as NSString).expandingTildeInPath)")
    }
}
