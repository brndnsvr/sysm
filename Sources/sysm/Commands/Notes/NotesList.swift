import ArgumentParser
import Foundation
import SysmCore

struct NotesList: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List notes in a folder"
    )

    @Option(name: .long, help: "Folder name (defaults to 'Notes' folder)")
    var folder: String = "Notes"

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.notes()
        let notes = try service.listNotes(folder: folder)

        if json {
            let jsonNotes = notes.map { ["name": $0.name, "folder": $0.folder, "id": $0.id] }
            try OutputFormatter.printJSON(jsonNotes)
        } else {
            print("Notes in '\(folder)' (\(notes.count)):")
            for note in notes {
                print("  - \(note.name)")
            }
        }
    }
}
