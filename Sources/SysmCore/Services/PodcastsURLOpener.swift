import Foundation

protocol PodcastsURLOpening: Sendable {
    func open(_ url: URL) throws
}

struct PodcastsURLOpener: PodcastsURLOpening {
    private static let playButtonIdentifier = "podcasts.productPage.playPauseButton"

    func open(_ url: URL) throws {
        do {
            _ = try Shell.run(
                "/usr/bin/open",
                args: ["-a", "Podcasts", url.absoluteString],
                timeout: 10
            )
        } catch {
            throw PodcastsError.playbackFailed(error.localizedDescription)
        }

        try PodcastsAccessibility.requirePermission()

        for _ in 0..<100 {
            if let button = PodcastsAccessibility.element(identifier: Self.playButtonIdentifier) {
                if PodcastsAccessibility.description(of: button) == "Pause" {
                    return
                }
                try PodcastsAccessibility.press(button)
                return
            }
            Thread.sleep(forTimeInterval: 0.1)
        }
        throw PodcastsError.playbackFailed("Timed out waiting for the episode page to load")
    }

}
