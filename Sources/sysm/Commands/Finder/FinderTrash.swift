import ArgumentParser
import Foundation
import SysmCore

struct FinderTrash: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "trash",
        abstract: "Move a file or folder to Trash"
    )

    @Argument(help: "Path to move to Trash")
    var path: String

    @Flag(name: .shortAndLong, help: "Skip confirmation")
    var force = false

    func run() throws {
        if !force {
            guard CLI.confirm("Move '\(path)' to Trash?") else {
                print("Cancelled")
                return
            }
        }

        let service = Services.finder()
        try service.trash(path: path)
        print("Moved to Trash: \(path)")
    }
}
