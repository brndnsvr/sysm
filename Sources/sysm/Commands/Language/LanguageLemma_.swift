import ArgumentParser
import Foundation
import SysmCore

struct LanguageLemma_: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "lemma",
        abstract: "Lemmatize text"
    )

    @Argument(help: "Text to analyze")
    var text: String?

    @Option(name: .long, help: "Read text from file")
    var file: String?

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let input = try loadText()
        let service = Services.language()
        let lemmas = try service.lemmatize(text: input)

        if json {
            try OutputFormatter.printJSON(lemmas)
        } else {
            for lemma in lemmas {
                print("  \(lemma.text) \u{2192} \(lemma.lemma)")
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
