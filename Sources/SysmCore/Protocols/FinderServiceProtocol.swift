import Foundation

public protocol FinderServiceProtocol: Sendable {
    /// Open a path in Finder.
    func open(path: String) throws

    /// Reveal and select a file in Finder.
    func reveal(path: String) throws

    /// Get file/folder info.
    func getInfo(path: String) throws -> FileInfo

    /// Move a file to Trash.
    func trash(path: String) throws

    /// Empty the Trash (requires confirmation).
    func emptyTrash() throws
}
