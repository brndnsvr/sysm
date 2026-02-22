import ArgumentParser
import Foundation
import SysmCore

struct PDFOutline_: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "outline",
        abstract: "Print the table of contents"
    )

    @Argument(help: "PDF file path")
    var input: String

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.pdf()
        let entries = try service.outline(path: input)

        if json {
            try OutputFormatter.printJSON(entries)
        } else {
            if entries.isEmpty {
                print("No outline found")
            } else {
                printEntries(entries)
            }
        }
    }

    private func printEntries(_ entries: [PDFOutlineEntry], indent: Int = 0) {
        let prefix = String(repeating: "  ", count: indent)
        for entry in entries {
            let pageStr = entry.pageIndex.map { " (p.\($0))" } ?? ""
            print("\(prefix)\(entry.title)\(pageStr)")
            if !entry.children.isEmpty {
                printEntries(entry.children, indent: indent + 1)
            }
        }
    }
}
