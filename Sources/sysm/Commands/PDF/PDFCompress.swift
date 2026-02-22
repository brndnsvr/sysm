import ArgumentParser
import Foundation
import SysmCore

struct PDFCompress: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "compress",
        abstract: "Compress images in a PDF"
    )

    @Argument(help: "PDF file path")
    var input: String

    @Option(name: .shortAndLong, help: "Output PDF path")
    var output: String

    func run() throws {
        let service = Services.pdf()
        try service.compress(path: input, outputPath: output)
        print("Compressed PDF saved to: \((output as NSString).expandingTildeInPath)")
    }
}
