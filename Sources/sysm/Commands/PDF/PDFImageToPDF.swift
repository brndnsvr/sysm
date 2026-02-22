import ArgumentParser
import Foundation
import SysmCore

struct PDFImageToPDF: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "image-to-pdf",
        abstract: "Convert images to PDF pages"
    )

    @Argument(help: "Image file paths")
    var inputs: [String]

    @Option(name: .shortAndLong, help: "Output PDF path")
    var output: String

    func run() throws {
        let service = Services.pdf()
        try service.imagesToPDF(imagePaths: inputs, outputPath: output)
        print("Created PDF with \(inputs.count) page(s): \((output as NSString).expandingTildeInPath)")
    }
}
