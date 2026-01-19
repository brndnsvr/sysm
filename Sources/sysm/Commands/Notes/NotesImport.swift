import ArgumentParser
import Foundation
import SysmCore

struct NotesImport: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "import",
        abstract: "Import notes from Apple Notes to markdown files"
    )

    @Option(name: .long, help: "Folder to import from (defaults to 'Notes')")
    var folder: String = "Notes"

    @Option(name: .long, help: "Output directory for markdown files")
    var output: String = "~/_inbox"

    @Flag(name: .long, help: "Show what would be imported without actually importing")
    var dryRun = false

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.notes()
        let exporter = MarkdownExporter(outputDir: output)

        let notes = try service.getNotes(from: folder)
        let results = try exporter.exportNotes(notes, dryRun: dryRun)

        if json {
            let jsonResults = results.map { ["name": $0.note.name, "path": $0.path.path] }
            try OutputFormatter.printJSON(jsonResults)
        } else {
            if results.isEmpty {
                print("No new notes to import from '\(folder)'")
            } else {
                let action = dryRun ? "Would import" : "Imported"
                print("\(action) \(results.count) note(s) from '\(folder)':")
                for (note, path) in results {
                    print("  - \(note.name) -> \(path.lastPathComponent)")
                }

                if dryRun {
                    print("")
                    print("Run without --dry-run to actually import")
                }
            }
        }
    }
}
