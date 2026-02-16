import ArgumentParser
import Foundation
import SysmCore

struct PhotosRecent: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "recent",
        abstract: "List recent photos or videos"
    )

    @Option(name: .shortAndLong, help: "Limit number of results")
    var limit: Int = 20

    @Flag(name: .long, help: "Show recent videos instead of photos")
    var videos = false

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let service = Services.photos()
        let assets: [PhotoAsset]
        let label: String

        if videos {
            assets = try await service.getRecentVideos(limit: limit)
            label = "Videos"
        } else {
            assets = try await service.getRecentPhotos(limit: limit)
            label = "Photos"
        }

        if json {
            try OutputFormatter.printJSON(assets)
        } else {
            if assets.isEmpty {
                print("No recent \(label.lowercased()) found")
            } else {
                print("Recent \(label) (\(assets.count)):\n")
                for asset in assets {
                    print("  - \(asset.formatted())")
                    print("    ID: \(asset.id)")
                }
            }
        }
    }
}
