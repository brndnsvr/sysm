import ArgumentParser
import Foundation
import SysmCore

struct LanguageEntities: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "entities",
        abstract: "Extract named entities from text"
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
        let entities = try service.entities(text: input)

        if json {
            try OutputFormatter.printJSON(entities)
        } else {
            if entities.isEmpty {
                print("No entities found")
            } else {
                for entity in entities {
                    print("  \(entity.type): \(entity.text)")
                }
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
