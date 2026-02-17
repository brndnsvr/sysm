import Foundation

public struct BookInfo: Codable, Sendable {
    public let title: String
    public let author: String?
    public let path: String?

    public init(title: String, author: String?, path: String?) {
        self.title = title
        self.author = author
        self.path = path
    }
}

public struct BookCollection: Codable, Sendable {
    public let name: String
    public let bookCount: Int

    public init(name: String, bookCount: Int) {
        self.name = name
        self.bookCount = bookCount
    }
}
