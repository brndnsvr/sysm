import ArgumentParser
import SysmCore

struct BooksCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "books",
        abstract: "Apple Books library",
        subcommands: [
            BooksList.self,
            BooksCollections.self,
        ]
    )
}
