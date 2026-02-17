import ArgumentParser
import SysmCore

struct PodcastsCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "podcasts",
        abstract: "Control Podcasts app",
        subcommands: [
            PodcastsShows.self,
            PodcastsEpisodes.self,
            PodcastsNowPlaying.self,
            PodcastsPlay.self,
            PodcastsPause.self,
        ]
    )
}
