import ArgumentParser
import Foundation
import SysmCore

struct NotesCreateFolder: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create-folder",
        abstract: "Create a new notes folder"
    )

    @Argument(help: "Name of the folder to create")
    var name: String

    func run() throws {
        let service = Services.notes()

        do {
            try service.createFolder(name: name)
            print("Created folder '\(name)'")
        } catch {
            fputs("Error: \(error.localizedDescription)\n", stderr)
            throw ExitCode.failure
        }
    }
}
