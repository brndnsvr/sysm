import ArgumentParser
import Foundation
import SysmCore

struct NotesDuplicate: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "duplicate",
        abstract: "Duplicate a note"
    )

    @Argument(help: "Note ID to duplicate")
    var noteId: String

    @Option(name: .long, help: "New name for the duplicate (defaults to original name + ' copy')")
    var name: String?

    @Flag(name: .shortAndLong, help: "Output as JSON")
    var json: Bool = false

    func run() throws {
        let service = Services.notes()

        // Verify original note exists
        guard let original = try service.getNote(id: noteId) else {
            throw NotesError.noteNotFound(noteId)
        }

        let newId = try service.duplicateNote(id: noteId, newName: name)
        let newName = name ?? "\(original.name) copy"

        if json {
            let output = ["id": newId, "name": newName, "folder": original.folder]
            try OutputFormatter.printJSON(output)
        } else {
            print("Duplicated '\(original.name)' to '\(newName)'")
            print("New note ID: \(newId)")
        }
    }
}
