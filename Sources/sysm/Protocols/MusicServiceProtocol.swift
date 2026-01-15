import Foundation

/// Protocol for music service operations
protocol MusicServiceProtocol {
    func play() throws
    func pause() throws
    func nextTrack() throws
    func previousTrack() throws
    func setVolume(_ level: Int) throws
    func getStatus() throws -> MusicService.NowPlaying?
    func listPlaylists() throws -> [MusicService.Playlist]
    func searchLibrary(query: String, limit: Int) throws -> [MusicService.Track]
}
