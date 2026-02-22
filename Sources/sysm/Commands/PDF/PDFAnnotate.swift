import ArgumentParser
import Foundation
import SysmCore

struct PDFAnnotate: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "annotate",
        abstract: "Add an annotation to a PDF page"
    )

    @Argument(help: "PDF file path")
    var input: String

    @Option(name: .long, help: "Page number (1-based)")
    var page: Int

    @Option(name: .long, help: "Annotation type (note, text)")
    var type: String = "note"

    @Option(name: .long, help: "Annotation text")
    var text: String

    @Option(name: .long, help: "X position")
    var x: Double

    @Option(name: .long, help: "Y position")
    var y: Double

    @Option(name: .shortAndLong, help: "Output PDF path")
    var output: String

    func run() throws {
        let service = Services.pdf()
        try service.addAnnotation(path: input, page: page, type: type,
                                  text: text, x: x, y: y, outputPath: output)
        print("Annotation added, saved to: \((output as NSString).expandingTildeInPath)")
    }
}
