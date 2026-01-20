import Foundation

/// Repeat mode options for Music playback.
public enum RepeatMode: String, CaseIterable {
    case off
    case one
    case all

    public var appleScriptValue: String {
        switch self {
        case .off: return "off"
        case .one: return "one"
        case .all: return "all"
        }
    }
}

/// Protocol defining music service operations for controlling macOS Music app via AppleScript.
///
/// Implementations provide playback control and library access for Apple Music,
/// supporting play/pause, track navigation, volume, shuffle, repeat, and playlist queries.
public protocol MusicServiceProtocol: Sendable {
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
    func getStatus() throws -> NowPlaying?

    /// Lists all playlists.
    /// - Returns: Array of playlists.
    func listPlaylists() throws -> [Playlist]

    /// Searches the music library.
    /// - Parameters:
    ///   - query: Search query string.
    ///   - limit: Maximum number of results.
    /// - Returns: Array of matching tracks.
    func searchLibrary(query: String, limit: Int) throws -> [Track]

    // MARK: - Repeat and Shuffle

    /// Gets the current shuffle state.
    /// - Returns: True if shuffle is enabled.
    func getShuffle() throws -> Bool

    /// Sets the shuffle state.
    /// - Parameter enabled: True to enable shuffle.
    func setShuffle(_ enabled: Bool) throws

    /// Gets the current repeat mode.
    /// - Returns: Current repeat mode.
    func getRepeatMode() throws -> RepeatMode

    /// Sets the repeat mode.
    /// - Parameter mode: Repeat mode to set.
    func setRepeatMode(_ mode: RepeatMode) throws

    // MARK: - Playback Controls

    /// Plays a specific playlist.
    /// - Parameter name: Name of the playlist to play.
    func playPlaylist(_ name: String) throws

    /// Plays a specific track by searching for it.
    /// - Parameter query: Search query to find and play.
    func playTrack(_ query: String) throws

    /// Adds a track to play next in the queue.
    /// - Parameter query: Search query to find and queue.
    func playNext(_ query: String) throws
}
