import ArgumentParser
import Foundation
import SysmCore

struct LanguageTag_: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "tag",
        abstract: "Part-of-speech tagging"
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
        let tags = try service.tag(text: input)

        if json {
            try OutputFormatter.printJSON(tags)
        } else {
            for tag in tags {
                print("  \(tag.text): \(tag.tag)")
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
