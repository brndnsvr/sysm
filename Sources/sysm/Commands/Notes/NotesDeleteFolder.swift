import ArgumentParser
import Foundation
import SysmCore

struct NotesDeleteFolder: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete-folder",
        abstract: "Delete a notes folder"
    )

    @Argument(help: "Name of the folder to delete")
    var name: String

    @Flag(name: .shortAndLong, help: "Skip confirmation prompt")
    var force: Bool = false

    func run() throws {
        let service = Services.notes()

        if !force {
            guard CLI.confirm("Delete folder '\(name)' and all its notes? [y/N] ") else { return }
        }

        do {
            try service.deleteFolder(name: name)
            print("Folder '\(name)' deleted")
        } catch {
            fputs("Error: \(error.localizedDescription)\n", stderr)
            throw ExitCode.failure
        }
    }
}
