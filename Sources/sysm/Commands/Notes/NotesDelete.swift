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
            // Try to get note name for confirmation
            if let note = try? service.getNote(id: id) {
                print("Delete note '\(note.name)'? [y/N]: ", terminator: "")
            } else {
                print("Delete note with ID '\(id)'? [y/N]: ", terminator: "")
            }

            guard let response = readLine(), response.lowercased() == "y" else {
                print("Cancelled")
                return
            }
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
