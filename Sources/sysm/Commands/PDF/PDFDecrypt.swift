import ArgumentParser
import Foundation
import SysmCore

struct PDFDecrypt: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "decrypt",
        abstract: "Remove password protection from a PDF"
    )

    @Argument(help: "PDF file path")
    var input: String

    @Option(name: .long, help: "Password to unlock the PDF")
    var password: String

    @Option(name: .shortAndLong, help: "Output PDF path")
    var output: String

    func run() throws {
        let service = Services.pdf()
        try service.decrypt(path: input, password: password, outputPath: output)
        print("Decrypted PDF saved to: \((output as NSString).expandingTildeInPath)")
    }
}
