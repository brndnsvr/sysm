import ArgumentParser
import SysmCore

struct AICommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "ai",
        abstract: "On-device AI with Apple Intelligence",
        subcommands: [
            AIPrompt.self,
            AISummarize.self,
            AIExtractActions.self,
            AIAnalyze.self,
        ]
    )
}
