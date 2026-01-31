import Foundation

public struct MarkdownExporter: MarkdownExporterProtocol {

    public init() {}

    // MARK: - Protocol Methods

    public func loadImportedIds(outputDir: URL) -> Set<String> {
        let trackingFile = outputDir.appendingPathComponent(".imported_notes.json")
        guard let data = try? Data(contentsOf: trackingFile),
              let ids = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return Set(ids)
    }

    public func saveImportedIds(_ ids: Set<String>, outputDir: URL) throws {
        let trackingFile = outputDir.appendingPathComponent(".imported_notes.json")
        let data = try JSONEncoder().encode(Array(ids))
        try data.write(to: trackingFile)
    }

    public func exportNote(_ note: Note, outputDir: URL, dryRun: Bool = false) throws -> URL {
        let filename = "\(note.sanitizedName).md"
        let fileURL = outputDir.appendingPathComponent(filename)

        if !dryRun {
            // Create output directory if needed
            try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

            // Write markdown content
            let content = note.toMarkdown()
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
        }

        return fileURL
    }

    /// Export notes to markdown files
    /// - Parameters:
    ///   - notes: Notes to export
    ///   - outputDir: Output directory for markdown files
    ///   - dryRun: If true, don't actually write files
    ///   - deferTracking: If true, don't update tracking file (caller will use `markAsImported` later)
    /// - Returns: Array of exported notes with their file paths
    public func exportNotes(_ notes: [Note], outputDir: URL, dryRun: Bool = false, deferTracking: Bool = false) throws -> [(note: Note, path: URL)] {
        var results: [(Note, URL)] = []
        var importedIds = loadImportedIds(outputDir: outputDir)

        for note in notes {
            // Skip already imported notes
            if importedIds.contains(note.id) {
                continue
            }

            let path = try exportNote(note, outputDir: outputDir, dryRun: dryRun)
            results.append((note, path))

            if !dryRun && !deferTracking {
                importedIds.insert(note.id)
            }
        }

        if !dryRun && !deferTracking {
            try saveImportedIds(importedIds, outputDir: outputDir)
        }

        return results
    }

    /// Mark notes as imported after external confirmation (e.g., after successful deletion)
    /// - Parameters:
    ///   - ids: Note IDs to mark as imported
    ///   - outputDir: Output directory containing the tracking file
    public func markAsImported(_ ids: [String], outputDir: URL) throws {
        guard !ids.isEmpty else { return }
        var importedIds = loadImportedIds(outputDir: outputDir)
        for id in ids {
            importedIds.insert(id)
        }
        try saveImportedIds(importedIds, outputDir: outputDir)
    }

    public func checkForNew(_ notes: [Note], outputDir: URL) -> [Note] {
        let importedIds = loadImportedIds(outputDir: outputDir)
        return notes.filter { !importedIds.contains($0.id) }
    }
}
