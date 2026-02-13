import ArgumentParser
import Foundation
import SysmCore

struct NotesAppend: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "append",
        abstract: "Append content to an existing note"
    )

    @Argument(help: "Note ID to append to")
    var noteId: String

    @Argument(help: "Content to append")
    var content: String

    func run() throws {
        let service = Services.notes()

        // Verify note exists
        guard let note = try service.getNote(id: noteId) else {
            throw NotesError.noteNotFound(noteId)
        }

        try service.appendToNote(id: noteId, content: content)
        print("Appended content to '\(note.name)'")
    }
}
