import ArgumentParser
import Foundation
import SysmCore

struct PDFPages: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "pages",
        abstract: "List pages with dimensions and metadata"
    )

    @Argument(help: "PDF file path")
    var input: String

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.pdf()
        let pages = try service.pages(path: input)

        if json {
            try OutputFormatter.printJSON(pages)
        } else {
            for page in pages {
                let label = page.label ?? "\(page.index)"
                print("Page \(label): \(Int(page.width)) x \(Int(page.height))", terminator: "")
                if page.rotation != 0 {
                    print(", rotation: \(page.rotation)\u{00B0}", terminator: "")
                }
                print(", \(page.characterCount) chars, \(page.annotationCount) annotations")
            }
        }
    }
}
