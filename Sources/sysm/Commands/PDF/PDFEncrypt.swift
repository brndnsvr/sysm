import ArgumentParser
import Foundation
import SysmCore

struct PDFEncrypt: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "encrypt",
        abstract: "Add password protection to a PDF"
    )

    @Argument(help: "PDF file path")
    var input: String

    @Option(name: .long, help: "Owner password")
    var ownerPassword: String

    @Option(name: .long, help: "User password (optional)")
    var userPassword: String?

    @Option(name: .shortAndLong, help: "Output PDF path")
    var output: String

    func run() throws {
        let service = Services.pdf()
        try service.encrypt(path: input, ownerPassword: ownerPassword,
                           userPassword: userPassword, outputPath: output)
        print("Encrypted PDF saved to: \((output as NSString).expandingTildeInPath)")
    }
}
