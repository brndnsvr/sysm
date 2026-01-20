import ArgumentParser
import Foundation
import SysmCore

struct PhotosVideos: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "videos",
        abstract: "List videos from the Photos library"
    )

    @Option(name: .shortAndLong, help: "Album ID to filter by")
    var album: String?

    @Option(name: .shortAndLong, help: "Maximum number of videos to return")
    var limit: Int = 20

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let service = Services.photos()

        do {
            let videos = try await service.listVideos(albumId: album, limit: limit)

            if json {
                try OutputFormatter.printJSON(videos)
            } else {
                if videos.isEmpty {
                    print("No videos found")
                } else {
                    print("Videos (\(videos.count)):")
                    for video in videos {
                        print("  \(video.formatted())")
                    }
                }
            }
        } catch {
            fputs("Error: \(error.localizedDescription)\n", stderr)
            throw ExitCode.failure
        }
    }
}
