import ArgumentParser
import Foundation
import SysmCore

struct PDFRotate: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "rotate",
        abstract: "Rotate pages in a PDF"
    )

    @Argument(help: "PDF file path")
    var input: String

    @Option(name: .long, help: "Comma-separated page numbers (e.g. 1,3,5)")
    var pages: String

    @Option(name: .long, help: "Rotation angle (0, 90, 180, 270)")
    var angle: Int

    @Option(name: .shortAndLong, help: "Output PDF path")
    var output: String

    func run() throws {
        let pageNums = pages.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        guard !pageNums.isEmpty else {
            throw ValidationError("No valid page numbers provided")
        }

        let service = Services.pdf()
        try service.rotate(path: input, pages: pageNums, angle: angle, outputPath: output)
        print("Rotated pages \(pages) by \(angle)\u{00B0} to: \((output as NSString).expandingTildeInPath)")
    }
}
