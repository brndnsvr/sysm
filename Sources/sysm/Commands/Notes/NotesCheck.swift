import ArgumentParser
import Foundation

struct NotesCheck: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "check",
        abstract: "Check for new notes without importing"
    )

    @Option(name: .long, help: "Folder to check (defaults to 'Notes')")
    var folder: String = "Notes"

    @Option(name: .long, help: "Output directory for tracking state")
    var output: String = "~/_inbox"

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.notes()
        let exporter = MarkdownExporter(outputDir: output)

        let notes = try service.getNotes(from: folder)
        let newNotes = exporter.checkForNew(notes)

        if json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(newNotes)
            print(String(data: data, encoding: .utf8)!)
        } else {
            if newNotes.isEmpty {
                print("No new notes in '\(folder)'")
            } else {
                print("Found \(newNotes.count) new note(s) in '\(folder)':")
                for note in newNotes {
                    print("  - \(note.name)")
                }
                print("")
                print("Run 'sysm notes import --folder \"\(folder)\"' to import them")
            }
        }
    }
}
