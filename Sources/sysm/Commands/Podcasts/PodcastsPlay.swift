import ArgumentParser
import Foundation
import SysmCore

struct PodcastsPlay: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "play",
        abstract: "Play or resume podcast playback"
    )

    @Argument(help: "Episode title to play (resumes if omitted)")
    var episode: String?

    func run() throws {
        let service = Services.podcasts()
        if let title = episode {
            try service.playEpisode(title: title)
            print("Playing: \(title)")
        } else {
            try service.play()
            print("Playback resumed")
        }
    }
}
