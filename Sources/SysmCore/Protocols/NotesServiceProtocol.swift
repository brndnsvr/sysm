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

    /// Creates a new note.
    /// - Parameters:
    ///   - name: The title of the note.
    ///   - body: The body content (can include HTML for formatting).
    ///   - folder: Optional folder name (uses default folder if nil).
    /// - Returns: The ID of the created note.
    func createNote(name: String, body: String, folder: String?) throws -> String

    /// Updates an existing note.
    /// - Parameters:
    ///   - id: The note's unique identifier.
    ///   - name: New title (nil to keep existing).
    ///   - body: New body content (nil to keep existing).
    func updateNote(id: String, name: String?, body: String?) throws

    /// Deletes a note.
    /// - Parameter id: The note's unique identifier.
    func deleteNote(id: String) throws

    /// Creates a new folder.
    /// - Parameter name: The folder name.
    func createFolder(name: String) throws

    /// Deletes a folder.
    /// - Parameter name: The folder name.
    /// - Note: This will also delete all notes in the folder.
    func deleteFolder(name: String) throws

    // MARK: - Advanced Operations

    /// Searches notes by title and/or body content.
    /// - Parameters:
    ///   - query: Search query string.
    ///   - searchBody: True to search in body, false for title only.
    ///   - folder: Optional folder to limit search scope.
    /// - Returns: Array of matching notes.
    func searchNotes(query: String, searchBody: Bool, folder: String?) throws -> [Note]

    /// Moves a note to a different folder.
    /// - Parameters:
    ///   - id: The note's unique identifier.
    ///   - toFolder: The destination folder name.
    func moveNote(id: String, toFolder: String) throws

    /// Appends content to an existing note.
    /// - Parameters:
    ///   - id: The note's unique identifier.
    ///   - content: Content to append.
    func appendToNote(id: String, content: String) throws

    /// Duplicates a note.
    /// - Parameters:
    ///   - id: The note's unique identifier.
    ///   - newName: Optional new name for the duplicate.
    /// - Returns: The ID of the duplicated note.
    func duplicateNote(id: String, newName: String?) throws -> String
}
