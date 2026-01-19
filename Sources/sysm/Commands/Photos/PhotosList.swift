import ArgumentParser
import Foundation
import SysmCore

struct PhotosList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List photos in an album"
    )

    @Argument(help: "Album ID (use 'albums' command to find)")
    var albumId: String

    @Option(name: .shortAndLong, help: "Limit number of results")
    var limit: Int = 50

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let service = Services.photos()
        let photos = try await service.listPhotos(albumId: albumId, limit: limit)

        if json {
            try OutputFormatter.printJSON(photos)
        } else {
            if photos.isEmpty {
                print("No photos in album")
            } else {
                print("Photos (\(photos.count)):\n")
                for photo in photos {
                    print("  - \(photo.formatted())")
                    print("    ID: \(photo.id)")
                }
            }
        }
    }
}
