import ArgumentParser
import Foundation
import SysmCore

struct PDFMetadata_: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "metadata",
        abstract: "Show or set PDF metadata",
        subcommands: [
            PDFMetadataShow.self,
            PDFMetadataSet.self,
        ],
        defaultSubcommand: PDFMetadataShow.self
    )
}

struct PDFMetadataShow: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "show",
        abstract: "Show PDF metadata"
    )

    @Argument(help: "PDF file path")
    var input: String

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.pdf()
        let info = try service.metadata(path: input)

        if json {
            try OutputFormatter.printJSON(info)
        } else {
            print("Metadata for: \(info.path)")
            print("  Title: \(info.title ?? "(none)")")
            print("  Author: \(info.author ?? "(none)")")
            print("  Subject: \(info.subject ?? "(none)")")
            print("  Creator: \(info.creator ?? "(none)")")
            print("  Producer: \(info.producer ?? "(none)")")
            if let date = info.creationDate { print("  Created: \(date)") }
            if let date = info.modificationDate { print("  Modified: \(date)") }
            if let keywords = info.keywords, !keywords.isEmpty {
                print("  Keywords: \(keywords.joined(separator: ", "))")
            }
        }
    }
}
