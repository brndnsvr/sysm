import ArgumentParser
import Foundation
import SysmCore

struct PodcastsPause: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "pause",
        abstract: "Pause podcast playback"
    )

    func run() throws {
        let service = Services.podcasts()
        try service.pause()
        print("Playback paused")
    }
}
