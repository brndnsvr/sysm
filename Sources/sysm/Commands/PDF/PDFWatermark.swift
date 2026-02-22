import ArgumentParser
import Foundation
import SysmCore

struct PDFWatermark: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "watermark",
        abstract: "Add a text watermark to all pages"
    )

    @Argument(help: "PDF file path")
    var input: String

    @Option(name: .long, help: "Watermark text")
    var text: String

    @Option(name: .long, help: "Font size")
    var fontSize: Double = 48.0

    @Option(name: .long, help: "Opacity (0.0-1.0)")
    var opacity: Double = 0.3

    @Option(name: .long, help: "Rotation angle in degrees")
    var angle: Double = -45.0

    @Option(name: .shortAndLong, help: "Output PDF path")
    var output: String

    func run() throws {
        let service = Services.pdf()
        try service.watermark(path: input, text: text, fontSize: fontSize,
                             opacity: opacity, angle: angle, outputPath: output)
        print("Watermarked PDF saved to: \((output as NSString).expandingTildeInPath)")
    }
}
