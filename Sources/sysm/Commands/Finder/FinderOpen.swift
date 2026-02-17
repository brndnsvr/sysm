import ArgumentParser
import Foundation
import SysmCore

struct FinderOpen: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "open",
        abstract: "Open a path in Finder"
    )

    @Argument(help: "Path to open")
    var path: String

    func run() throws {
        let service = Services.finder()
        try service.open(path: path)
        print("Opened in Finder: \(path)")
    }
}
