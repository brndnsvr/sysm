import ArgumentParser
import Foundation

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
        let service = NotesService()
        let notes = try service.listNotes(folder: folder)

        if json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let jsonNotes = notes.map { ["name": $0.name, "folder": $0.folder, "id": $0.id] }
            let data = try encoder.encode(jsonNotes)
            print(String(data: data, encoding: .utf8)!)
        } else {
            print("Notes in '\(folder)' (\(notes.count)):")
            for note in notes {
                print("  - \(note.name)")
            }
        }
    }
}
