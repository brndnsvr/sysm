import ArgumentParser
import Foundation
import SysmCore

// MARK: - Output Models

private struct NotesImportResult: Encodable {
    let imported: [ImportedNote]
    let deleteFailures: [DeleteFailure]?
}

private struct ImportedNote: Encodable {
    let name: String
    let path: String
}

private struct DeleteFailure: Encodable {
    let name: String
    let error: String
    let errorType: String
}

// MARK: - Command

struct NotesImport: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "import",
        abstract: "Import notes from Apple Notes to markdown files"
    )

    @Option(name: .long, help: "Folder to import from (defaults to 'Notes')")
    var folder: String = "Notes"

    @Option(name: .long, help: "Output directory for markdown files")
    var output: String = "~/_inbox"

    @Option(name: .long, parsing: .upToNextOption, help: "Exclude notes with titles containing pattern (case-insensitive, repeatable)")
    var exclude: [String] = []

    @Flag(name: .long, help: "Delete notes from Apple Notes after successful import")
    var delete = false

    @Flag(name: .long, help: "Show what would be imported without actually importing")
    var dryRun = false

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.notes()
        let exporter = MarkdownExporter(outputDir: output)

        let notes = try service.getNotes(from: folder)

        // Filter out excluded notes
        let filteredNotes = notes.filter { note in
            !exclude.contains { pattern in
                note.name.localizedCaseInsensitiveContains(pattern)
            }
        }

        // When --delete is used, defer tracking until after successful deletion
        let results = try exporter.exportNotes(filteredNotes, dryRun: dryRun, deferTracking: delete)

        // Delete imported notes from Apple Notes if requested
        var deleteFailures: [(note: Note, error: Error)] = []
        var successfullyDeletedIds: [String] = []

        if delete && !dryRun && !results.isEmpty {
            for (note, _) in results {
                do {
                    try service.deleteNote(id: note.id)
                    successfullyDeletedIds.append(note.id)
                } catch {
                    deleteFailures.append((note: note, error: error))
                }
            }

            // Only track notes that were successfully deleted
            if !successfullyDeletedIds.isEmpty {
                try exporter.markAsImported(successfullyDeletedIds)
            }
        } else if !delete && !dryRun {
            // When not deleting, track all exported notes immediately
            let exportedIds = results.map { $0.note.id }
            if !exportedIds.isEmpty {
                try exporter.markAsImported(exportedIds)
            }
        }

        if json {
            let importedNotes = results.map { ImportedNote(name: $0.note.name, path: $0.path.path) }
            let failures: [DeleteFailure]? = deleteFailures.isEmpty ? nil : deleteFailures.map {
                DeleteFailure(
                    name: $0.note.name,
                    error: $0.error.localizedDescription,
                    errorType: String(describing: type(of: $0.error))
                )
            }
            try OutputFormatter.printJSON(NotesImportResult(imported: importedNotes, deleteFailures: failures))
        } else {
            if results.isEmpty {
                if exclude.isEmpty {
                    print("No new notes to import from '\(folder)'")
                } else {
                    print("No new notes to import from '\(folder)' (excluding \(exclude.count) pattern(s))")
                }
            } else {
                let deletedCount = delete && !dryRun ? successfullyDeletedIds.count : 0
                let action = dryRun ? "Would import" : "Imported"
                var deleteAction = ""
                if delete && !dryRun {
                    if deleteFailures.isEmpty {
                        deleteAction = " and deleted from Apple Notes"
                    } else if deletedCount > 0 {
                        deleteAction = " (deleted \(deletedCount) from Apple Notes)"
                    }
                }
                print("\(action) \(results.count) note(s) from '\(folder)'\(deleteAction):")
                for (note, path) in results {
                    print("  - \(note.name) -> \(path.lastPathComponent)")
                }

                if !deleteFailures.isEmpty {
                    print("")
                    print("Partial success: deleted \(deletedCount) of \(results.count) note(s)")
                    print("Failed to delete \(deleteFailures.count) note(s):")
                    for (note, error) in deleteFailures {
                        print("  - \(note.name): \(error.localizedDescription)")
                    }
                }

                if dryRun {
                    print("")
                    print("Run without --dry-run to actually import")
                    if delete {
                        print("Notes will be deleted from Apple Notes when not in dry-run mode")
                    }
                }
            }
        }

        if !deleteFailures.isEmpty {
            // Exit code 2 for partial success: imports OK, some deletes failed
            throw ExitCode(2)
        }
    }
}
