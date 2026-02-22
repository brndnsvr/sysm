import ArgumentParser
import Foundation
import SysmCore

struct PDFMetadataSet: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "set",
        abstract: "Set PDF metadata fields"
    )

    @Argument(help: "PDF file path")
    var input: String

    @Option(name: .long, help: "Document title")
    var title: String?

    @Option(name: .long, help: "Document author")
    var author: String?

    @Option(name: .long, help: "Document subject")
    var subject: String?

    @Option(name: .long, help: "Comma-separated keywords")
    var keywords: String?

    @Option(name: .shortAndLong, help: "Output PDF path")
    var output: String

    func run() throws {
        let keywordList = keywords?.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }

        let service = Services.pdf()
        try service.setMetadata(path: input, title: title, author: author,
                               subject: subject, keywords: keywordList, outputPath: output)
        print("Metadata updated, saved to: \((output as NSString).expandingTildeInPath)")
    }
}
