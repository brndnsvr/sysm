import CryptoKit
import Foundation

public enum MarkdownExporterError: LocalizedError, Equatable {
    case duplicateNoteId(String)
    case nonUniqueOutputPath(String)

    public var errorDescription: String? {
        switch self {
        case let .duplicateNoteId(id):
            return "The export batch contains duplicate note ID: \(id)"
        case let .nonUniqueOutputPath(path):
            return "The export batch contains a duplicate output path: \(path)"
        }
    }
}

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
        try data.write(to: trackingFile, options: .atomic)
    }

    public func exportNote(_ note: Note, outputDir: URL, dryRun: Bool = false) throws -> URL {
        let filename = exportFilename(for: note)
        let fileURL = outputDir.appendingPathComponent(filename)
        try write(note, to: fileURL, outputDir: outputDir, dryRun: dryRun)
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
        let pendingNotes = notes.filter { !importedIds.contains($0.id) }
        let plan = try makeExportPlan(for: pendingNotes, outputDir: outputDir)

        for (note, path) in plan {
            try write(note, to: path, outputDir: outputDir, dryRun: dryRun)
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

    private func exportFilename(for note: Note) -> String {
        let digest = SHA256.hash(data: Data(note.id.utf8))
            .prefix(8)
            .map { String(format: "%02x", $0) }
            .joined()
        return "\(note.sanitizedName)--\(digest).md"
    }

    private func write(
        _ note: Note,
        to fileURL: URL,
        outputDir: URL,
        dryRun: Bool
    ) throws {
        guard !dryRun else { return }
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
        try note.toMarkdown().write(to: fileURL, atomically: true, encoding: .utf8)
    }

    private func makeExportPlan(
        for notes: [Note],
        outputDir: URL
    ) throws -> [(note: Note, path: URL)] {
        var sourceIds: Set<String> = []
        var outputPaths: Set<String> = []
        var plan: [(note: Note, path: URL)] = []

        for note in notes {
            guard sourceIds.insert(note.id).inserted else {
                throw MarkdownExporterError.duplicateNoteId(note.id)
            }

            let path = outputDir.appendingPathComponent(exportFilename(for: note))
            let pathKey = canonicalOutputKey(path)
            guard outputPaths.insert(pathKey).inserted else {
                throw MarkdownExporterError.nonUniqueOutputPath(path.path)
            }
            plan.append((note, path))
        }

        return plan
    }

    private func canonicalOutputKey(_ url: URL) -> String {
        url.standardizedFileURL.path
            .precomposedStringWithCanonicalMapping
            .lowercased()
    }
}
