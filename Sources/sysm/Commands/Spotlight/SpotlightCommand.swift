import ArgumentParser
import SysmCore

struct SpotlightCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "spotlight",
        abstract: "Search files using Spotlight",
        subcommands: [
            SpotlightSearch.self,
            SpotlightKind.self,
            SpotlightModified.self,
            SpotlightMetadata.self,
        ],
        defaultSubcommand: SpotlightSearch.self
    )
}
