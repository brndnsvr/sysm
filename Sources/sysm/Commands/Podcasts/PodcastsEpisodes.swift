import ArgumentParser
import Foundation
import SysmCore

struct PodcastsEpisodes: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "episodes",
        abstract: "List episodes for a show"
    )

    @Argument(help: "Show name")
    var show: String

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.podcasts()
        let episodes = try service.listEpisodes(showName: show)

        if json {
            try OutputFormatter.printJSON(episodes)
        } else {
            if episodes.isEmpty {
                print("No episodes found for '\(show)'")
            } else {
                print("Episodes for '\(show)' (\(episodes.count)):\n")
                for ep in episodes {
                    let date = ep.date.map { " (\($0))" } ?? ""
                    print("  \(ep.title)\(date)")
                }
            }
        }
    }
}
