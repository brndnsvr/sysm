import Foundation

/// Protocol defining markdown export operations for notes.
///
/// Implementations handle exporting Apple Notes to markdown files
/// with tracking to avoid duplicate imports.
public protocol MarkdownExporterProtocol: Sendable {
    /// Loads previously imported note IDs from the tracking file.
    /// - Parameter outputDir: The output directory containing the tracking file.
    func loadImportedIds(outputDir: URL) -> Set<String>

    /// Saves imported note IDs to the tracking file.
    /// - Parameters:
    ///   - ids: Set of note IDs that have been imported.
    ///   - outputDir: The output directory for the tracking file.
    func saveImportedIds(_ ids: Set<String>, outputDir: URL) throws

    /// Exports a single note to markdown.
    /// - Parameters:
    ///   - note: The note to export.
    ///   - outputDir: The output directory.
    ///   - dryRun: If true, don't actually write files.
    /// - Returns: The URL where the file was/would be written.
    func exportNote(_ note: Note, outputDir: URL, dryRun: Bool) throws -> URL

    /// Exports multiple notes to markdown files.
    /// - Parameters:
    ///   - notes: Notes to export.
    ///   - outputDir: The output directory.
    ///   - dryRun: If true, don't actually write files.
    ///   - deferTracking: If true, don't update tracking file.
    /// - Returns: Array of exported notes with their file paths.
    func exportNotes(_ notes: [Note], outputDir: URL, dryRun: Bool, deferTracking: Bool) throws -> [(note: Note, path: URL)]

    /// Marks notes as imported after external confirmation.
    /// - Parameters:
    ///   - ids: Note IDs to mark as imported.
    ///   - outputDir: The output directory for the tracking file.
    func markAsImported(_ ids: [String], outputDir: URL) throws

    /// Checks for notes not yet imported.
    /// - Parameters:
    ///   - notes: Current list of notes.
    ///   - outputDir: The output directory containing the tracking file.
    /// - Returns: Notes that haven't been imported yet.
    func checkForNew(_ notes: [Note], outputDir: URL) -> [Note]
}
