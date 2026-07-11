import Foundation

public struct PodcastsService: PodcastsServiceProtocol {
    private let library: any PodcastsLibraryProtocol
    private let playbackController: any PodcastsPlaybackControlling
    private let urlOpener: any PodcastsURLOpening

    public init() {
        library = PodcastsLibraryStore()
        playbackController = AccessibilityPodcastsPlaybackController()
        urlOpener = PodcastsURLOpener()
    }

    init(
        library: any PodcastsLibraryProtocol,
        playbackController: any PodcastsPlaybackControlling,
        urlOpener: any PodcastsURLOpening
    ) {
        self.library = library
        self.playbackController = playbackController
        self.urlOpener = urlOpener
    }

    public func listShows() throws -> [PodcastShow] {
        try library.listShows()
    }

    public func listEpisodes(showName: String) throws -> [PodcastEpisode] {
        try library.listEpisodes(showName: showName, limit: 20)
    }

    public func nowPlaying() throws -> PodcastEpisode? {
        try library.currentEpisode()
    }

    public func play() throws {
        try playbackController.play()
    }

    public func pause() throws {
        try playbackController.pause()
    }

    public func playEpisode(title: String) throws {
        guard let episode = try library.episode(matchingTitle: title) else {
            throw PodcastsError.episodeNotFound(title)
        }
        guard let url = episode.url else {
            throw PodcastsError.episodeMissingIdentifier(title)
        }
        try urlOpener.open(url)
    }
}

public enum PodcastsError: LocalizedError {
    case episodeNotFound(String)
    case showNotFound(String)
    case episodeMissingIdentifier(String)
    case libraryUnavailable
    case databaseReadFailed(String)
    case invalidLibraryData(String)
    case playbackFailed(String)

    public var errorDescription: String? {
        switch self {
        case .episodeNotFound(let title):
            return "Episode not found: \(title)"
        case .showNotFound(let name):
            return "Show not found: \(name)"
        case .episodeMissingIdentifier(let title):
            return "Episode cannot be opened because it has no playback identifier: \(title)"
        case .libraryUnavailable:
            return "Podcasts library is unavailable. Open Podcasts.app once and try again."
        case .databaseReadFailed(let message):
            return "Could not read the Podcasts library: \(message)"
        case .invalidLibraryData(let message):
            return "Could not decode the Podcasts library: \(message)"
        case .playbackFailed(let message):
            return "Could not start podcast playback: \(message)"
        }
    }
}
