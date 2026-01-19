import ArgumentParser
import Foundation
import SysmCore

struct MusicSearch: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "search",
        abstract: "Search music library"
    )

    @Argument(help: "Search query")
    var query: String

    @Option(name: .shortAndLong, help: "Limit number of results")
    var limit: Int = 20

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.music()
        let tracks = try service.searchLibrary(query: query, limit: limit)

        if json {
            try OutputFormatter.printJSON(tracks)
        } else {
            if tracks.isEmpty {
                print("No tracks found for '\(query)'")
            } else {
                print("Search results for '\(query)' (\(tracks.count)):\n")
                for track in tracks {
                    print("  - \(track.formatted())")
                }
            }
        }
    }
}
