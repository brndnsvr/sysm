import ArgumentParser
import Foundation
import SysmCore

struct PDFOCR: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "ocr",
        abstract: "Embed OCR text layer in a PDF"
    )

    @Argument(help: "PDF file path")
    var input: String

    @Option(name: .shortAndLong, help: "Output PDF path")
    var output: String

    func run() throws {
        let service = Services.pdf()
        try service.ocrEmbed(path: input, outputPath: output)
        print("OCR text layer embedded, saved to: \((output as NSString).expandingTildeInPath)")
    }
}
