import ArgumentParser
import SysmCore

struct FinderCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "finder",
        abstract: "Finder operations",
        subcommands: [
            FinderOpen.self,
            FinderReveal.self,
            FinderInfo.self,
            FinderTrash.self,
        ]
    )
}
