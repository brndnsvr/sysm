import ArgumentParser
import Foundation
import SysmCore

struct BooksList: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List books in library"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.books()
        let books = try service.listBooks()

        if json {
            try OutputFormatter.printJSON(books)
        } else {
            if books.isEmpty {
                print("No books found")
            } else {
                print("Books (\(books.count)):\n")
                for book in books {
                    let author = book.author.map { " by \($0)" } ?? ""
                    print("  \(book.title)\(author)")
                }
            }
        }
    }
}
