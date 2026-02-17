import Foundation

public protocol PodcastsServiceProtocol: Sendable {
    func listShows() throws -> [PodcastShow]
    func listEpisodes(showName: String) throws -> [PodcastEpisode]
    func nowPlaying() throws -> PodcastEpisode?
    func play() throws
    func pause() throws
    func playEpisode(title: String) throws
}
