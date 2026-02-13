import Foundation

/// Protocol defining markdown export operations for Apple Notes.
///
/// This protocol handles exporting Apple Notes to markdown files with tracking to avoid duplicate
/// imports. Supports single note export, batch export, dry-run mode, and deferred tracking for
/// external confirmation workflows. Maintains a tracking file to remember which notes have been
/// exported.
///
/// ## Tracking System
///
/// The exporter maintains a `.sysm-imported-notes` file in the output directory tracking
/// which note IDs have been exported. This prevents re-exporting the same note multiple times.
///
/// ## Usage Example
///
/// ```swift
/// let exporter = MarkdownExporter()
/// let outputDir = URL(fileURLWithPath: "/Users/me/exported-notes")
///
/// // Check for new notes
/// let allNotes = try notesService.listNotes(folder: nil)
/// let newNotes = exporter.checkForNew(allNotes, outputDir: outputDir)
/// print("\(newNotes.count) new notes to export")
///
/// // Export with dry-run
/// let results = try exporter.exportNotes(
///     newNotes,
///     outputDir: outputDir,
///     dryRun: true,
///     deferTracking: false
/// )
///
/// // Export for real
/// let exported = try exporter.exportNotes(
///     newNotes,
///     outputDir: outputDir,
///     dryRun: false,
///     deferTracking: false
/// )
/// ```
///
/// ## Thread Safety
///
/// Implementations are marked as `Sendable` and safe to use across actor boundaries.
/// File operations are synchronous.
///
/// ## Error Handling
///
/// Methods can throw standard file system errors:
/// - File write errors
/// - Directory access errors
/// - Permission errors
///
public protocol MarkdownExporterProtocol: Sendable {
    // MARK: - Tracking Management

    /// Loads previously imported note IDs from the tracking file.
    ///
    /// Reads the `.sysm-imported-notes` file in the output directory to determine which
    /// notes have already been exported. Returns an empty set if no tracking file exists.
    ///
    /// - Parameter outputDir: The output directory containing the tracking file.
    /// - Returns: Set of note IDs that have been previously imported.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let imported = exporter.loadImportedIds(outputDir: outputURL)
    /// print("\(imported.count) notes previously exported")
    /// ```
    func loadImportedIds(outputDir: URL) -> Set<String>

    /// Saves imported note IDs to the tracking file.
    ///
    /// Writes the set of imported note IDs to `.sysm-imported-notes` in the output directory.
    /// Creates the tracking file if it doesn't exist.
    ///
    /// - Parameters:
    ///   - ids: Set of note IDs that have been imported.
    ///   - outputDir: The output directory for the tracking file.
    /// - Throws: File system errors if unable to write tracking file.
    func saveImportedIds(_ ids: Set<String>, outputDir: URL) throws

    /// Marks notes as imported after external confirmation.
    ///
    /// Updates the tracking file to include the specified note IDs without actually
    /// exporting them. Useful for confirming successful imports in external systems.
    ///
    /// - Parameters:
    ///   - ids: Note IDs to mark as imported.
    ///   - outputDir: The output directory for the tracking file.
    /// - Throws: File system errors if unable to update tracking file.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // After confirming notes were imported to external system
    /// try exporter.markAsImported(
    ///     ["note-id-1", "note-id-2"],
    ///     outputDir: outputURL
    /// )
    /// ```
    func markAsImported(_ ids: [String], outputDir: URL) throws

    // MARK: - Export Operations

    /// Exports a single note to markdown.
    ///
    /// Converts a note's HTML content to markdown and writes it to a file. The filename
    /// is derived from the note's title (sanitized for filesystem safety).
    ///
    /// - Parameters:
    ///   - note: The ``Note`` to export.
    ///   - outputDir: The output directory for the markdown file.
    ///   - dryRun: If true, simulates export without writing files.
    /// - Returns: The URL where the file was/would be written.
    /// - Throws: File system errors if unable to write file (unless dryRun is true).
    ///
    /// ## Example
    ///
    /// ```swift
    /// let note = try notesService.getNote(id: "ABC123")!
    /// let path = try exporter.exportNote(
    ///     note,
    ///     outputDir: outputURL,
    ///     dryRun: false
    /// )
    /// print("Exported to: \(path.path)")
    /// ```
    ///
    /// ## File Naming
    ///
    /// - Note title is sanitized (removing invalid filename characters)
    /// - Extension is `.md`
    /// - Duplicate names get numeric suffixes (e.g., `note-1.md`, `note-2.md`)
    func exportNote(_ note: Note, outputDir: URL, dryRun: Bool) throws -> URL

    /// Exports multiple notes to markdown files.
    ///
    /// Batch exports notes to markdown. Optionally updates the tracking file to record
    /// the export (unless deferTracking is true).
    ///
    /// - Parameters:
    ///   - notes: Notes to export.
    ///   - outputDir: The output directory for markdown files.
    ///   - dryRun: If true, simulates export without writing files.
    ///   - deferTracking: If true, doesn't update the tracking file (for external confirmation workflows).
    /// - Returns: Array of tuples containing each note and its export file path.
    /// - Throws: File system errors if unable to write files (unless dryRun is true).
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Export with tracking
    /// let results = try exporter.exportNotes(
    ///     notes,
    ///     outputDir: outputURL,
    ///     dryRun: false,
    ///     deferTracking: false
    /// )
    /// print("Exported \(results.count) notes")
    ///
    /// // Export without tracking (for confirmation later)
    /// let pending = try exporter.exportNotes(
    ///     notes,
    ///     outputDir: outputURL,
    ///     dryRun: false,
    ///     deferTracking: true
    /// )
    /// // Later, after confirmation:
    /// try exporter.markAsImported(pending.map { $0.note.id }, outputDir: outputURL)
    /// ```
    func exportNotes(_ notes: [Note], outputDir: URL, dryRun: Bool, deferTracking: Bool) throws -> [(note: Note, path: URL)]

    // MARK: - New Notes Detection

    /// Checks for notes not yet imported.
    ///
    /// Compares the provided notes against the tracking file to identify which notes
    /// have not been exported yet.
    ///
    /// - Parameters:
    ///   - notes: Current list of notes from Notes.app.
    ///   - outputDir: The output directory containing the tracking file.
    /// - Returns: Notes that haven't been imported yet.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let allNotes = try notesService.listNotes(folder: "Work")
    /// let newNotes = exporter.checkForNew(allNotes, outputDir: outputURL)
    ///
    /// if newNotes.isEmpty {
    ///     print("No new notes to export")
    /// } else {
    ///     print("Found \(newNotes.count) new notes:")
    ///     for note in newNotes {
    ///         print("  - \(note.name)")
    ///     }
    /// }
    /// ```
    func checkForNew(_ notes: [Note], outputDir: URL) -> [Note]
}
