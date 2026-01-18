import Foundation

/// Protocol defining music service operations for controlling macOS Music app via AppleScript.
///
/// Implementations provide playback control and library access for Apple Music,
/// supporting play/pause, track navigation, volume, and playlist queries.
protocol MusicServiceProtocol: Sendable {
    /// Starts or resumes playback.
    func play() throws

    /// Pauses playback.
    func pause() throws

    /// Skips to the next track.
    func nextTrack() throws

    /// Returns to the previous track.
    func previousTrack() throws

    /// Sets the volume level.
    /// - Parameter level: Volume level from 0 to 100.
    func setVolume(_ level: Int) throws

    /// Gets the currently playing track information.
    /// - Returns: Now playing info, or nil if nothing is playing.
    func getStatus() throws -> MusicService.NowPlaying?

    /// Lists all playlists.
    /// - Returns: Array of playlists.
    func listPlaylists() throws -> [MusicService.Playlist]

    /// Searches the music library.
    /// - Parameters:
    ///   - query: Search query string.
    ///   - limit: Maximum number of results.
    /// - Returns: Array of matching tracks.
    func searchLibrary(query: String, limit: Int) throws -> [MusicService.Track]
}
