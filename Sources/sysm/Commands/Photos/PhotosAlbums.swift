import ArgumentParser
import Foundation

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
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(albums)
            print(String(data: data, encoding: .utf8)!)
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
