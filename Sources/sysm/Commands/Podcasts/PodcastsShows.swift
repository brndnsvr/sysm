import ArgumentParser
import Foundation
import SysmCore

struct PodcastsShows: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "shows",
        abstract: "List subscribed podcast shows"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.podcasts()
        let shows = try service.listShows()

        if json {
            try OutputFormatter.printJSON(shows)
        } else {
            if shows.isEmpty {
                print("No podcast shows found")
            } else {
                print("Podcast Shows (\(shows.count)):\n")
                for show in shows {
                    let author = show.author.map { " by \($0)" } ?? ""
                    print("  \(show.name)\(author)")
                    print("    Episodes: \(show.episodeCount)")
                }
            }
        }
    }
}
