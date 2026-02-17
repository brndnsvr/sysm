import Foundation

public protocol BooksServiceProtocol: Sendable {
    func listBooks() throws -> [BookInfo]
    func listCollections() throws -> [BookCollection]
}
