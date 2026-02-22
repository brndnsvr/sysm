import ArgumentParser
import Foundation
import SysmCore

struct PDFAnnotations: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "annotations",
        abstract: "List annotations in a PDF"
    )

    @Argument(help: "PDF file path")
    var input: String

    @Option(name: .long, help: "Filter to specific page (1-based)")
    var page: Int?

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.pdf()
        let annotations = try service.annotations(path: input, page: page)

        if json {
            try OutputFormatter.printJSON(annotations)
        } else {
            if annotations.isEmpty {
                print("No annotations found")
            } else {
                print("Found \(annotations.count) annotation(s):")
                for ann in annotations {
                    print("  Page \(ann.page): [\(ann.type)]", terminator: "")
                    if let contents = ann.contents, !contents.isEmpty {
                        print(" \"\(contents)\"", terminator: "")
                    }
                    print(" at (\(Int(ann.boundsX)), \(Int(ann.boundsY)))")
                }
            }
        }
    }
}
