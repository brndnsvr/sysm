import Foundation

public struct MarkdownExporter {
    public let outputDir: URL
    public let trackingFile: URL

    public init(outputDir: String) {
        self.outputDir = URL(fileURLWithPath: (outputDir as NSString).expandingTildeInPath)
        self.trackingFile = self.outputDir.appendingPathComponent(".imported_notes.json")
    }

    public func loadImportedIds() -> Set<String> {
        guard let data = try? Data(contentsOf: trackingFile),
              let ids = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return Set(ids)
    }

    public func saveImportedIds(_ ids: Set<String>) throws {
        let data = try JSONEncoder().encode(Array(ids))
        try data.write(to: trackingFile)
    }

    public func exportNote(_ note: Note, dryRun: Bool = false) throws -> URL {
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
    ///   - dryRun: If true, don't actually write files
    ///   - deferTracking: If true, don't update tracking file (caller will use `markAsImported` later)
    /// - Returns: Array of exported notes with their file paths
    public func exportNotes(_ notes: [Note], dryRun: Bool = false, deferTracking: Bool = false) throws -> [(note: Note, path: URL)] {
        var results: [(Note, URL)] = []
        var importedIds = loadImportedIds()

        for note in notes {
            // Skip already imported notes
            if importedIds.contains(note.id) {
                continue
            }

            let path = try exportNote(note, dryRun: dryRun)
            results.append((note, path))

            if !dryRun && !deferTracking {
                importedIds.insert(note.id)
            }
        }

        if !dryRun && !deferTracking {
            try saveImportedIds(importedIds)
        }

        return results
    }

    /// Mark notes as imported after external confirmation (e.g., after successful deletion)
    /// - Parameter ids: Note IDs to mark as imported
    public func markAsImported(_ ids: [String]) throws {
        guard !ids.isEmpty else { return }
        var importedIds = loadImportedIds()
        for id in ids {
            importedIds.insert(id)
        }
        try saveImportedIds(importedIds)
    }

    public func checkForNew(_ notes: [Note]) -> [Note] {
        let importedIds = loadImportedIds()
        return notes.filter { !importedIds.contains($0.id) }
    }
}
