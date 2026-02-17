import ArgumentParser
import Foundation
import SysmCore

struct BooksCollections: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "collections",
        abstract: "List book collections"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.books()
        let collections = try service.listCollections()

        if json {
            try OutputFormatter.printJSON(collections)
        } else {
            if collections.isEmpty {
                print("No collections found")
            } else {
                print("Collections (\(collections.count)):\n")
                for collection in collections {
                    print("  \(collection.name) (\(collection.bookCount) books)")
                }
            }
        }
    }
}
