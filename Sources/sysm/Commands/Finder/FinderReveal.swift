import ArgumentParser
import Foundation
import SysmCore

struct FinderReveal: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "reveal",
        abstract: "Reveal and select a file in Finder"
    )

    @Argument(help: "Path to reveal")
    var path: String

    func run() throws {
        let service = Services.finder()
        try service.reveal(path: path)
        print("Revealed in Finder: \(path)")
    }
}
