import Foundation

/// Protocol defining notes service operations for accessing and managing macOS Notes via AppleScript.
///
/// This protocol provides comprehensive access to the user's notes through the Notes app,
/// supporting folder management, note CRUD operations, search capabilities, content manipulation,
/// and note organization. Operations use AppleScript to interact with the Notes application.
///
/// ## Permission Requirements
///
/// Notes app integration uses AppleScript and may require:
/// - Automation permission for controlling Notes.app
/// - System Settings > Privacy & Security > Automation
/// - Notes.app must be running for operations
///
/// ## Usage Example
///
/// ```swift
/// let service = NotesService()
///
/// // List all folders
/// let folders = try service.listFolders()
/// print("Folders: \(folders.joined(separator: ", "))")
///
/// // Create a new note
/// let noteId = try service.createNote(
///     name: "Meeting Notes",
///     body: "<h1>Q1 Planning</h1><ul><li>Budget review</li><li>Hiring plan</li></ul>",
///     folder: "Work"
/// )
///
/// // Search notes
/// let results = try service.searchNotes(
///     query: "planning",
///     searchBody: true,
///     folder: nil
/// )
///
/// // Append to existing note
/// try service.appendToNote(id: noteId, content: "\n<li>Timeline discussion</li>")
/// ```
///
/// ## Thread Safety
///
/// Implementations are marked as `Sendable` and safe to use across actor boundaries.
/// AppleScript operations are synchronous and blocking.
///
/// ## Error Handling
///
/// All methods can throw ``NotesError`` variants:
/// - ``NotesError/notesNotRunning`` - Notes.app is not running
/// - ``NotesError/folderNotFound(_:)`` - Folder not found
/// - ``NotesError/noteNotFound(_:)`` - Note not found by ID
/// - ``NotesError/scriptFailed(_:)`` - AppleScript execution failed
/// - ``NotesError/createFailed(_:)`` - Note or folder creation failed
/// - ``NotesError/updateFailed(_:)`` - Note update failed
/// - ``NotesError/deleteFailed(_:)`` - Delete operation failed
///
public protocol NotesServiceProtocol: Sendable {
    // MARK: - Folder Management

    /// Lists all note folders.
    ///
    /// Returns the names of all folders (including iCloud and local folders) in the Notes app.
    ///
    /// - Returns: Array of folder names.
    /// - Throws: ``NotesError/notesNotRunning`` if Notes.app is not running.
    func listFolders() throws -> [String]

    /// Creates a new folder.
    ///
    /// Creates an empty folder in Notes. Folder names do not need to be unique.
    ///
    /// - Parameter name: The display name for the new folder.
    /// - Throws:
    ///   - ``NotesError/notesNotRunning`` if Notes.app is not running.
    ///   - ``NotesError/createFailed(_:)`` if folder creation failed.
    func createFolder(name: String) throws

    /// Deletes a folder.
    ///
    /// Permanently deletes the folder and all notes it contains. This operation cannot be undone.
    ///
    /// - Parameter name: The folder name to delete.
    /// - Throws:
    ///   - ``NotesError/notesNotRunning`` if Notes.app is not running.
    ///   - ``NotesError/folderNotFound(_:)`` if folder doesn't exist.
    ///   - ``NotesError/deleteFailed(_:)`` if deletion failed.
    ///
    /// ## Warning
    ///
    /// This will delete all notes in the folder. Consider moving notes to another folder first.
    func deleteFolder(name: String) throws

    // MARK: - Note Queries

    /// Lists notes, optionally filtered by folder.
    ///
    /// Returns basic information about notes. Results include note names, folders, and IDs.
    ///
    /// - Parameter folder: Optional folder name to filter by. If nil, returns notes from all folders.
    /// - Returns: Array of tuples containing note name, folder name, and unique ID.
    /// - Throws: ``NotesError/notesNotRunning`` if Notes.app is not running.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let allNotes = try service.listNotes(folder: nil)
    /// for (name, folder, id) in allNotes {
    ///     print("\(name) in \(folder)")
    /// }
    /// ```
    func listNotes(folder: String?) throws -> [(name: String, folder: String, id: String)]

    /// Retrieves a specific note by ID with full content.
    ///
    /// Returns complete note information including the full body content.
    ///
    /// - Parameter id: The note's unique identifier.
    /// - Returns: ``Note`` object if found, nil if note doesn't exist.
    /// - Throws: ``NotesError/notesNotRunning`` if Notes.app is not running.
    func getNote(id: String) throws -> Note?

    /// Retrieves all notes from a folder with full content.
    ///
    /// Returns all notes in the specified folder, including their complete body content.
    ///
    /// - Parameter folder: The folder name.
    /// - Returns: Array of ``Note`` objects from the folder.
    /// - Throws:
    ///   - ``NotesError/notesNotRunning`` if Notes.app is not running.
    ///   - ``NotesError/folderNotFound(_:)`` if folder doesn't exist.
    func getNotes(from folder: String) throws -> [Note]

    /// Counts notes, optionally filtered by folder.
    ///
    /// Returns the total number of notes, either across all folders or within a specific folder.
    ///
    /// - Parameter folder: Optional folder name to filter by. If nil, counts all notes.
    /// - Returns: Number of notes.
    /// - Throws: ``NotesError/notesNotRunning`` if Notes.app is not running.
    func countNotes(folder: String?) throws -> Int

    // MARK: - CRUD Operations

    /// Creates a new note.
    ///
    /// Creates a note with the specified title and content. The body can include HTML formatting
    /// tags for rich text (e.g., `<h1>`, `<b>`, `<ul>`, `<li>`).
    ///
    /// - Parameters:
    ///   - name: The title of the note.
    ///   - body: The body content. Supports HTML for formatting.
    ///   - folder: Optional folder name. If nil, uses the default Notes folder.
    /// - Returns: The unique identifier of the created note.
    /// - Throws:
    ///   - ``NotesError/notesNotRunning`` if Notes.app is not running.
    ///   - ``NotesError/folderNotFound(_:)`` if specified folder doesn't exist.
    ///   - ``NotesError/createFailed(_:)`` if note creation failed.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let noteId = try service.createNote(
    ///     name: "Shopping List",
    ///     body: "<ul><li>Milk</li><li>Bread</li><li>Eggs</li></ul>",
    ///     folder: "Personal"
    /// )
    /// ```
    func createNote(name: String, body: String, folder: String?) throws -> String

    /// Updates an existing note.
    ///
    /// Modifies the title and/or body of an existing note. Nil parameters leave the current
    /// value unchanged.
    ///
    /// - Parameters:
    ///   - id: The note's unique identifier.
    ///   - name: New title (nil to keep existing).
    ///   - body: New body content (nil to keep existing).
    /// - Throws:
    ///   - ``NotesError/notesNotRunning`` if Notes.app is not running.
    ///   - ``NotesError/noteNotFound(_:)`` if note doesn't exist.
    ///   - ``NotesError/updateFailed(_:)`` if update operation failed.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Update only the title
    /// try service.updateNote(id: "x-coredata://...", name: "Updated Title", body: nil)
    /// ```
    func updateNote(id: String, name: String?, body: String?) throws

    /// Deletes a note permanently.
    ///
    /// Removes the note from its folder. The note is moved to Recently Deleted initially
    /// (depending on Notes.app settings) but this is implementation-dependent.
    ///
    /// - Parameter id: The note's unique identifier.
    /// - Throws:
    ///   - ``NotesError/notesNotRunning`` if Notes.app is not running.
    ///   - ``NotesError/noteNotFound(_:)`` if note doesn't exist.
    ///   - ``NotesError/deleteFailed(_:)`` if deletion failed.
    func deleteNote(id: String) throws

    // MARK: - Advanced Operations

    /// Searches notes by title and/or body content.
    ///
    /// Performs case-insensitive search across note titles and optionally body content.
    /// Can be scoped to a specific folder.
    ///
    /// - Parameters:
    ///   - query: Search query string to match.
    ///   - searchBody: `true` to search in body content, `false` to search title only.
    ///   - folder: Optional folder to limit search scope. If nil, searches all folders.
    /// - Returns: Array of matching ``Note`` objects with full content.
    /// - Throws: ``NotesError/notesNotRunning`` if Notes.app is not running.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Search all notes for "project" in title and body
    /// let results = try service.searchNotes(
    ///     query: "project",
    ///     searchBody: true,
    ///     folder: nil
    /// )
    /// ```
    func searchNotes(query: String, searchBody: Bool, folder: String?) throws -> [Note]

    /// Moves a note to a different folder.
    ///
    /// Transfers the note from its current folder to the specified destination folder.
    ///
    /// - Parameters:
    ///   - id: The note's unique identifier.
    ///   - toFolder: The destination folder name.
    /// - Throws:
    ///   - ``NotesError/notesNotRunning`` if Notes.app is not running.
    ///   - ``NotesError/noteNotFound(_:)`` if note doesn't exist.
    ///   - ``NotesError/folderNotFound(_:)`` if destination folder doesn't exist.
    ///   - ``NotesError/updateFailed(_:)`` if move operation failed.
    ///
    /// ## Example
    ///
    /// ```swift
    /// try service.moveNote(id: noteId, toFolder: "Archive")
    /// ```
    func moveNote(id: String, toFolder: String) throws

    /// Appends content to an existing note.
    ///
    /// Adds new content to the end of a note's body. Useful for adding entries to ongoing notes
    /// like journals or logs. Content can include HTML formatting.
    ///
    /// - Parameters:
    ///   - id: The note's unique identifier.
    ///   - content: Content to append (can include HTML).
    /// - Throws:
    ///   - ``NotesError/notesNotRunning`` if Notes.app is not running.
    ///   - ``NotesError/noteNotFound(_:)`` if note doesn't exist.
    ///   - ``NotesError/updateFailed(_:)`` if append operation failed.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Add a timestamped entry
    /// let timestamp = Date().formatted()
    /// try service.appendToNote(
    ///     id: journalId,
    ///     content: "\n<p><b>\(timestamp)</b> - Today was productive.</p>"
    /// )
    /// ```
    func appendToNote(id: String, content: String) throws

    /// Duplicates a note, optionally with a new name.
    ///
    /// Creates a copy of an existing note in the same folder. The duplicate gets a new unique ID.
    ///
    /// - Parameters:
    ///   - id: The note's unique identifier to duplicate.
    ///   - newName: Optional new name for the duplicate. If nil, uses the original name with "Copy" appended.
    /// - Returns: The unique identifier of the duplicated note.
    /// - Throws:
    ///   - ``NotesError/notesNotRunning`` if Notes.app is not running.
    ///   - ``NotesError/noteNotFound(_:)`` if original note doesn't exist.
    ///   - ``NotesError/createFailed(_:)`` if duplication failed.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let duplicateId = try service.duplicateNote(
    ///     id: templateId,
    ///     newName: "Project Notes - New"
    /// )
    /// ```
    func duplicateNote(id: String, newName: String?) throws -> String
}
