import ArgumentParser
import Foundation
import SysmCore

struct PDFSplit: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "split",
        abstract: "Extract a page range to a new PDF"
    )

    @Argument(help: "PDF file path")
    var input: String

    @Option(name: .long, help: "Page range (e.g. 1-3)")
    var pages: String

    @Option(name: .shortAndLong, help: "Output PDF path")
    var output: String

    func run() throws {
        let range = try parsePageRange(pages)
        let service = Services.pdf()
        try service.split(path: input, pageRange: range, outputPath: output)
        print("Extracted pages \(range.lowerBound)-\(range.upperBound) to: \((output as NSString).expandingTildeInPath)")
    }

    private func parsePageRange(_ str: String) throws -> ClosedRange<Int> {
        let parts = str.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 2, parts[0] >= 1, parts[1] >= parts[0] else {
            throw ValidationError("Invalid page range '\(str)'. Use format: 1-3")
        }
        return parts[0]...parts[1]
    }
}
