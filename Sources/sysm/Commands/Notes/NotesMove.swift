import ArgumentParser
import Foundation
import SysmCore

struct NotesMove: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "move",
        abstract: "Move a note to a different folder"
    )

    @Argument(help: "Note ID to move")
    var noteId: String

    @Argument(help: "Destination folder name")
    var toFolder: String

    func run() throws {
        let service = Services.notes()

        // Verify note exists before moving
        guard let note = try service.getNote(id: noteId) else {
            throw NotesError.noteNotFound(noteId)
        }

        try service.moveNote(id: noteId, toFolder: toFolder)
        print("Moved '\(note.name)' from '\(note.folder)' to '\(toFolder)'")
    }
}
