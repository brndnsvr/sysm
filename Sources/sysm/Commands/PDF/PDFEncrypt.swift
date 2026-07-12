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

    @Flag(name: .long, help: "Read the owner password from non-terminal stdin")
    var ownerPasswordStdin = false

    @Option(name: .long, help: "Read the owner password from an inherited file descriptor (3 or greater)")
    var ownerPasswordFd: Int?

    @Flag(name: .long, help: "Prompt securely for an optional user password")
    var userPasswordPrompt = false

    @Flag(name: .long, help: "Read the optional user password from non-terminal stdin")
    var userPasswordStdin = false

    @Option(name: .long, help: "Read the optional user password from an inherited file descriptor (3 or greater)")
    var userPasswordFd: Int?

    @Option(name: .shortAndLong, help: "Output PDF path")
    var output: String

    func validate() throws {
        let ownerSource = try ownerSource()
        let userSource = try userSource()

        if ownerSource == .standardInput, userSource == .standardInput {
            throw ValidationError("Owner and user passwords cannot both consume stdin")
        }

        if case .fileDescriptor(let ownerFd) = ownerSource,
           case .fileDescriptor(let userFd) = userSource,
           ownerFd == userFd {
            throw ValidationError("Owner and user passwords must use distinct file descriptors")
        }
    }

    func run() throws {
        try run(service: Services.pdf(), secretReader: SecretInputReader())
    }

    func run(
        service: any PDFServiceProtocol,
        secretReader: any SecretInputReading
    ) throws {
        let ownerPassword = try secretReader.read(
            from: ownerSource(),
            prompt: "PDF owner password: ",
            maximumBytes: 65_536
        )
        let userPassword = try userSource().map {
            try secretReader.read(
                from: $0,
                prompt: "PDF user password: ",
                maximumBytes: 65_536
            )
        }

        try service.encrypt(path: input, ownerPassword: ownerPassword,
                           userPassword: userPassword, outputPath: output)
        print("Encrypted PDF saved to: \((output as NSString).expandingTildeInPath)")
    }

    private func ownerSource() throws -> SecretInputSource {
        guard let source = try CLI.secretSource(
            standardInput: ownerPasswordStdin,
            fileDescriptor: ownerPasswordFd,
            defaultToPrompt: true,
            label: "PDF owner password"
        ) else {
            throw ValidationError("PDF owner password input is required")
        }
        return source
    }

    private func userSource() throws -> SecretInputSource? {
        try CLI.secretSource(
            prompt: userPasswordPrompt,
            standardInput: userPasswordStdin,
            fileDescriptor: userPasswordFd,
            defaultToPrompt: false,
            label: "PDF user password"
        )
    }
}
