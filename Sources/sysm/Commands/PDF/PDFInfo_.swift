import ArgumentParser
import Foundation
import SysmCore

struct PDFInfo_: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "info",
        abstract: "Show PDF information"
    )

    @Argument(help: "PDF file path")
    var input: String

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.pdf()
        let info = try service.info(path: input)

        if json {
            try OutputFormatter.printJSON(info)
        } else {
            print("PDF: \(info.path)")
            print("  Pages: \(info.pageCount)")
            print("  Version: \(info.versionMajor).\(info.versionMinor)")
            print("  Size: \(info.fileSizeFormatted)")
            print("  Encrypted: \(info.isEncrypted ? "Yes" : "No")")
            if let title = info.title { print("  Title: \(title)") }
            if let author = info.author { print("  Author: \(author)") }
            if let subject = info.subject { print("  Subject: \(subject)") }
            if let creator = info.creator { print("  Creator: \(creator)") }
            if let producer = info.producer { print("  Producer: \(producer)") }
            if let date = info.creationDate { print("  Created: \(date)") }
            if let date = info.modificationDate { print("  Modified: \(date)") }
            if let keywords = info.keywords, !keywords.isEmpty {
                print("  Keywords: \(keywords.joined(separator: ", "))")
            }
        }
    }
}
