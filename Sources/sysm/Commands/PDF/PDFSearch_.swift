import ArgumentParser
import Foundation
import SysmCore

struct PDFSearch_: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "search",
        abstract: "Search for text in a PDF"
    )

    @Argument(help: "PDF file path")
    var input: String

    @Argument(help: "Text to search for")
    var query: String

    @Flag(name: .long, help: "Case-sensitive search")
    var caseSensitive = false

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.pdf()
        let results = try service.search(path: input, query: query, caseSensitive: caseSensitive)

        if json {
            try OutputFormatter.printJSON(results)
        } else {
            if results.isEmpty {
                print("No results found for: \(query)")
            } else {
                print("Found \(results.count) result(s):")
                for result in results {
                    let label = result.pageLabel ?? "\(result.page)"
                    print("  Page \(label): \(result.contextSnippet)")
                }
            }
        }
    }
}
