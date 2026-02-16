import ArgumentParser
import Foundation
import SysmCore

struct NotesDelete: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a note"
    )

    @Argument(help: "ID of the note to delete")
    var id: String

    @Flag(name: .shortAndLong, help: "Skip confirmation prompt")
    var force: Bool = false

    func run() throws {
        let service = Services.notes()

        if !force {
            let prompt: String
            if let note = try? service.getNote(id: id) {
                prompt = "Delete note '\(note.name)'? [y/N] "
            } else {
                prompt = "Delete note with ID '\(id)'? [y/N] "
            }
            guard CLI.confirm(prompt) else { return }
        }

        do {
            try service.deleteNote(id: id)
            print("Note deleted")
        } catch {
            fputs("Error: \(error.localizedDescription)\n", stderr)
            throw ExitCode.failure
        }
    }
}
