import ArgumentParser
import SysmCore

struct LanguageCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "language",
        abstract: "Natural language processing",
        subcommands: [
            LanguageDetect.self,
            LanguageTokenize.self,
            LanguageEntities.self,
            LanguageTag_.self,
            LanguageLemma_.self,
        ]
    )
}
