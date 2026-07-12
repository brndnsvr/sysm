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

    @Flag(name: .long, help: "Read the password from non-terminal stdin")
    var passwordStdin = false

    @Option(name: .long, help: "Read the password from an inherited file descriptor (3 or greater)")
    var passwordFd: Int?

    @Option(name: .shortAndLong, help: "Output PDF path")
    var output: String

    func validate() throws {
        _ = try passwordSource()
    }

    func run() throws {
        try run(service: Services.pdf(), secretReader: SecretInputReader())
    }

    func run(
        service: any PDFServiceProtocol,
        secretReader: any SecretInputReading
    ) throws {
        let password = try secretReader.read(
            from: passwordSource(),
            prompt: "PDF password: ",
            maximumBytes: 65_536
        )
        try service.decrypt(path: input, password: password, outputPath: output)
        print("Decrypted PDF saved to: \((output as NSString).expandingTildeInPath)")
    }

    private func passwordSource() throws -> SecretInputSource {
        guard let source = try CLI.secretSource(
            standardInput: passwordStdin,
            fileDescriptor: passwordFd,
            defaultToPrompt: true,
            label: "PDF password"
        ) else {
            throw ValidationError("PDF password input is required")
        }
        return source
    }
}
