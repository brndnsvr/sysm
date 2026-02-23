import ArgumentParser
import Foundation
import SysmCore

extension TokenUnit: ExpressibleByArgument {}

struct LanguageTokenize: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "tokenize",
        abstract: "Tokenize text into units"
    )

    @Argument(help: "Text to tokenize")
    var text: String?

    @Option(name: .long, help: "Read text from file")
    var file: String?

    @Option(name: .long, help: "Token unit: word, sentence, paragraph")
    var unit: TokenUnit = .word

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let input = try loadText()
        let service = Services.language()
        let tokens = try service.tokenize(text: input, unit: unit)

        if json {
            try OutputFormatter.printJSON(tokens)
        } else {
            for token in tokens {
                print(token.text)
            }
        }
    }

    private func loadText() throws -> String {
        if let filePath = file {
            let expanded = (filePath as NSString).expandingTildeInPath
            guard FileManager.default.fileExists(atPath: expanded) else {
                throw LanguageError.fileNotFound(expanded)
            }
            return try String(contentsOfFile: expanded, encoding: .utf8)
        }
        guard let t = text else {
            throw LanguageError.emptyInput
        }
        return t
    }
}
