import ArgumentParser
import Foundation
import SysmCore

struct PDFMerge: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "merge",
        abstract: "Combine multiple PDFs into one"
    )

    @Argument(help: "PDF files to merge")
    var inputs: [String]

    @Option(name: .shortAndLong, help: "Output PDF path")
    var output: String

    func run() throws {
        let service = Services.pdf()
        try service.merge(paths: inputs, outputPath: output)
        print("Merged \(inputs.count) files to: \((output as NSString).expandingTildeInPath)")
    }
}
