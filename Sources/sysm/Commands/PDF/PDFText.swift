import ArgumentParser
import Foundation
import SysmCore

struct PDFText: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "text",
        abstract: "Extract text from a PDF"
    )

    @Argument(help: "PDF file path")
    var input: String

    @Option(name: .long, help: "Page number to extract (1-based)")
    var page: Int?

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.pdf()
        let text = try service.text(path: input, page: page)

        if json {
            try OutputFormatter.printJSON(["text": text])
        } else {
            print(text)
        }
    }
}
