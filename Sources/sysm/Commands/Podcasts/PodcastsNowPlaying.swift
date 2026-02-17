import ArgumentParser
import Foundation
import SysmCore

struct PodcastsNowPlaying: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "now-playing",
        abstract: "Show currently playing episode"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.podcasts()
        guard let episode = try service.nowPlaying() else {
            print("Nothing is currently playing")
            return
        }

        if json {
            try OutputFormatter.printJSON(episode)
        } else {
            print("Now Playing:")
            print("  \(episode.title)")
            if let show = episode.showName {
                print("  Show: \(show)")
            }
        }
    }
}
