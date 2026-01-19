import ArgumentParser
import Foundation
import SysmCore

struct PhotosRecent: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "recent",
        abstract: "List recent photos"
    )

    @Option(name: .shortAndLong, help: "Limit number of results")
    var limit: Int = 20

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let service = Services.photos()
        let photos = try await service.getRecentPhotos(limit: limit)

        if json {
            try OutputFormatter.printJSON(photos)
        } else {
            if photos.isEmpty {
                print("No recent photos found")
            } else {
                print("Recent Photos (\(photos.count)):\n")
                for photo in photos {
                    print("  - \(photo.formatted())")
                    print("    ID: \(photo.id)")
                }
            }
        }
    }
}
