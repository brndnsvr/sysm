import Foundation
import XCTest
@testable import SysmCore

final class PodcastsServiceTests: XCTestCase {
    private var library: MockPodcastsLibrary!
    private var playbackController: MockPodcastsPlaybackController!
    private var urlOpener: MockPodcastsURLOpener!
    private var service: PodcastsService!

    override func setUp() {
        super.setUp()
        library = MockPodcastsLibrary()
        playbackController = MockPodcastsPlaybackController()
        urlOpener = MockPodcastsURLOpener()
        service = PodcastsService(
            library: library,
            playbackController: playbackController,
            urlOpener: urlOpener
        )
    }

    func testListShowsUsesLibraryBackend() throws {
        library.shows = [PodcastShow(name: "Show, With Comma", episodeCount: 3, author: "Host")]

        let shows = try service.listShows()

        XCTAssertEqual(shows.count, 1)
        XCTAssertEqual(shows[0].name, "Show, With Comma")
    }

    func testListEpisodesUsesLibraryBackend() throws {
        library.episodes = [
            PodcastEpisode(title: "Episode", showName: "Show", date: nil, duration: "42:00", played: false),
        ]

        let episodes = try service.listEpisodes(showName: "Show")

        XCTAssertEqual(episodes.map(\.title), ["Episode"])
        XCTAssertEqual(library.requestedShowName, "Show")
        XCTAssertEqual(library.requestedLimit, 20)
    }

    func testNowPlayingUsesLibraryCurrentEpisode() throws {
        library.currentEpisodeValue = PodcastEpisode(
            title: "Current Episode",
            showName: "Current Show",
            date: nil,
            duration: "30:00",
            played: nil
        )

        let episode = try service.nowPlaying()

        XCTAssertEqual(episode?.title, "Current Episode")
    }

    func testPlayEpisodeOpensPublicEpisodeURL() throws {
        library.matchedEpisode = PodcastLibraryEpisode(
            title: "Episode & More",
            url: URL(string: "https://podcasts.apple.com/show/id123?i=456")
        )

        try service.playEpisode(title: "Episode & More")

        XCTAssertEqual(
            urlOpener.openedURL?.absoluteString,
            "https://podcasts.apple.com/show/id123?i=456"
        )
    }

    func testPlayEpisodeThrowsWhenNotFound() {
        XCTAssertThrowsError(try service.playEpisode(title: "Missing")) { error in
            guard case PodcastsError.episodeNotFound("Missing") = error else {
                XCTFail("Expected episodeNotFound, got \(error)")
                return
            }
        }
    }

    func testPlayAndPauseUsePlaybackController() throws {
        try service.play()
        try service.pause()

        XCTAssertEqual(playbackController.commands, [.play, .pause])
    }
}

private final class MockPodcastsPlaybackController: PodcastsPlaybackControlling, @unchecked Sendable {
    enum Command: Equatable {
        case play
        case pause
    }

    var commands: [Command] = []

    func play() throws {
        commands.append(.play)
    }

    func pause() throws {
        commands.append(.pause)
    }
}

private final class MockPodcastsLibrary: PodcastsLibraryProtocol, @unchecked Sendable {
    var shows: [PodcastShow] = []
    var episodes: [PodcastEpisode] = []
    var matchedEpisode: PodcastLibraryEpisode?
    var currentEpisodeValue: PodcastEpisode?
    var requestedShowName: String?
    var requestedLimit: Int?

    func listShows() throws -> [PodcastShow] {
        shows
    }

    func listEpisodes(showName: String, limit: Int) throws -> [PodcastEpisode] {
        requestedShowName = showName
        requestedLimit = limit
        return episodes
    }

    func episode(matchingTitle title: String) throws -> PodcastLibraryEpisode? {
        matchedEpisode
    }

    func currentEpisode() throws -> PodcastEpisode? {
        currentEpisodeValue
    }
}

private final class MockPodcastsURLOpener: PodcastsURLOpening, @unchecked Sendable {
    var openedURL: URL?

    func open(_ url: URL) throws {
        openedURL = url
    }
}
