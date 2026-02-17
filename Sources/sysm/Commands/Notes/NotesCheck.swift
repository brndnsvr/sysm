import ArgumentParser
import Foundation
import SysmCore

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
        let exporter = Services.markdownExporter()
        let outputDir = URL(fileURLWithPath: (output as NSString).expandingTildeInPath)

        let allNotes = try service.listNotes(folder: folder)
        let importedIds = exporter.loadImportedIds(outputDir: outputDir)
        let newNotes = allNotes.filter { !importedIds.contains($0.id) }

        if json {
            let jsonArray = newNotes.map { [
                "name": $0.name,
                "folder": $0.folder,
                "id": $0.id
            ] }
            try OutputFormatter.printJSON(jsonArray)
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
