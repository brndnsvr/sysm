import Foundation

/// Protocol for notes service operations
protocol NotesServiceProtocol {
    func listFolders() throws -> [String]
    func listNotes(folder: String?) throws -> [(name: String, folder: String, id: String)]
    func getNote(id: String) throws -> Note?
    func getNotes(from folder: String) throws -> [Note]
    func countNotes(folder: String?) throws -> Int
}
