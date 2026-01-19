import ArgumentParser
import Foundation
import SysmCore

struct PhotosAlbums: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "albums",
        abstract: "List photo albums"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let service = Services.photos()
        let albums = try await service.listAlbums()

        if json {
            try OutputFormatter.printJSON(albums)
        } else {
            if albums.isEmpty {
                print("No albums found")
            } else {
                print("Albums (\(albums.count)):\n")
                for album in albums {
                    print("  - \(album.formatted())")
                    print("    ID: \(album.id)")
                }
            }
        }
    }
}
