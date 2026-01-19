import Foundation

/// Protocol defining notes service operations for accessing macOS Notes via AppleScript.
///
/// Implementations provide read-only access to the user's notes, supporting
/// folder listing, note retrieval, and export to Markdown format.
public protocol NotesServiceProtocol: Sendable {
    /// Lists all note folders.
    /// - Returns: Array of folder names.
    func listFolders() throws -> [String]

    /// Lists notes, optionally filtered by folder.
    /// - Parameter folder: Optional folder name to filter by.
    /// - Returns: Array of tuples with note name, folder, and ID.
    func listNotes(folder: String?) throws -> [(name: String, folder: String, id: String)]

    /// Retrieves a specific note by ID.
    /// - Parameter id: The note's unique identifier.
    /// - Returns: The note if found, nil otherwise.
    func getNote(id: String) throws -> Note?

    /// Retrieves all notes from a folder.
    /// - Parameter folder: The folder name.
    /// - Returns: Array of notes in the folder.
    func getNotes(from folder: String) throws -> [Note]

    /// Counts notes, optionally filtered by folder.
    /// - Parameter folder: Optional folder name to filter by.
    /// - Returns: Number of notes.
    func countNotes(folder: String?) throws -> Int
}
