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
/// This protocol provides comprehensive playback control and library access for Apple Music,
/// supporting play/pause, track navigation, volume control, shuffle/repeat modes, playlist
/// management, and library search. Operations use AppleScript to interact with the Music application.
///
/// ## Permission Requirements
///
/// Music app integration uses AppleScript and may require:
/// - Automation permission for controlling Music.app
/// - System Settings > Privacy & Security > Automation
/// - Music.app must be running for most operations
///
/// ## Usage Example
///
/// ```swift
/// let service = MusicService()
///
/// // Play music
/// try service.play()
///
/// // Check what's playing
/// if let nowPlaying = try service.getStatus() {
///     print("Now playing: \(nowPlaying.name) by \(nowPlaying.artist)")
/// }
///
/// // Adjust volume and enable shuffle
/// try service.setVolume(75)
/// try service.setShuffle(true)
///
/// // Search and play
/// let results = try service.searchLibrary(query: "Daft Punk", limit: 10)
/// if let firstTrack = results.first {
///     try service.playTrack(firstTrack.name)
/// }
/// ```
///
/// ## Thread Safety
///
/// Implementations are marked as `Sendable` and safe to use across actor boundaries.
/// AppleScript operations are synchronous and blocking.
///
/// ## Error Handling
///
/// All methods can throw ``MusicError`` variants:
/// - ``MusicError/musicNotRunning`` - Music.app is not running
/// - ``MusicError/nothingPlaying`` - No track is currently playing
/// - ``MusicError/trackNotFound(_:)`` - Track not found in library
/// - ``MusicError/playlistNotFound(_:)`` - Playlist not found
/// - ``MusicError/invalidVolume(_:)`` - Volume level outside valid range (0-100)
/// - ``MusicError/scriptFailed(_:)`` - AppleScript execution failed
///
public protocol MusicServiceProtocol: Sendable {
    // MARK: - Playback Controls

    /// Starts or resumes playback.
    ///
    /// Plays the current track or resumes playback if paused. If no track is selected,
    /// plays from the beginning of the library or last played position.
    ///
    /// - Throws:
    ///   - ``MusicError/musicNotRunning`` if Music.app is not running.
    ///   - ``MusicError/scriptFailed(_:)`` if playback failed.
    func play() throws

    /// Pauses playback.
    ///
    /// Pauses the currently playing track. Playback position is preserved and can be
    /// resumed with ``play()``.
    ///
    /// - Throws:
    ///   - ``MusicError/musicNotRunning`` if Music.app is not running.
    ///   - ``MusicError/scriptFailed(_:)`` if pause failed.
    func pause() throws

    /// Skips to the next track.
    ///
    /// Advances to the next track in the current playlist or queue. If shuffle is enabled,
    /// plays a random next track.
    ///
    /// - Throws:
    ///   - ``MusicError/musicNotRunning`` if Music.app is not running.
    ///   - ``MusicError/scriptFailed(_:)`` if operation failed.
    func nextTrack() throws

    /// Returns to the previous track.
    ///
    /// Goes back to the previous track in the current playlist or queue. If called within
    /// a few seconds of a track starting, goes to the actual previous track; otherwise
    /// restarts the current track.
    ///
    /// - Throws:
    ///   - ``MusicError/musicNotRunning`` if Music.app is not running.
    ///   - ``MusicError/scriptFailed(_:)`` if operation failed.
    func previousTrack() throws

    /// Sets the volume level.
    ///
    /// Adjusts the Music app playback volume. This is independent of system volume.
    ///
    /// - Parameter level: Volume level from 0 (muted) to 100 (maximum).
    /// - Throws:
    ///   - ``MusicError/musicNotRunning`` if Music.app is not running.
    ///   - ``MusicError/invalidVolume(_:)`` if level is outside 0-100 range.
    ///
    /// ## Example
    ///
    /// ```swift
    /// try service.setVolume(50) // Set to 50%
    /// ```
    func setVolume(_ level: Int) throws

    // MARK: - Status

    /// Gets the currently playing track information.
    ///
    /// Returns detailed information about the track currently playing, including title,
    /// artist, album, duration, and playback position.
    ///
    /// - Returns: ``NowPlaying`` object if something is playing, nil if Music is idle.
    /// - Throws: ``MusicError/musicNotRunning`` if Music.app is not running.
    ///
    /// ## Example
    ///
    /// ```swift
    /// if let nowPlaying = try service.getStatus() {
    ///     print("\(nowPlaying.name)")
    ///     print("Artist: \(nowPlaying.artist)")
    ///     print("Album: \(nowPlaying.album)")
    /// } else {
    ///     print("Nothing playing")
    /// }
    /// ```
    func getStatus() throws -> NowPlaying?

    // MARK: - Library Management

    /// Lists all playlists.
    ///
    /// Returns all playlists in the Music library, including both user-created playlists
    /// and system playlists (Library, Recently Added, etc.).
    ///
    /// - Returns: Array of ``Playlist`` objects.
    /// - Throws: ``MusicError/musicNotRunning`` if Music.app is not running.
    func listPlaylists() throws -> [Playlist]

    /// Searches the music library.
    ///
    /// Performs a search across the library for tracks matching the query. Searches track
    /// names, artists, and albums.
    ///
    /// - Parameters:
    ///   - query: Search query string.
    ///   - limit: Maximum number of results to return.
    /// - Returns: Array of matching ``Track`` objects.
    /// - Throws: ``MusicError/musicNotRunning`` if Music.app is not running.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let results = try service.searchLibrary(query: "Beatles", limit: 20)
    /// for track in results {
    ///     print("\(track.name) - \(track.artist)")
    /// }
    /// ```
    func searchLibrary(query: String, limit: Int) throws -> [Track]

    // MARK: - Repeat and Shuffle

    /// Gets the current shuffle state.
    ///
    /// Returns whether shuffle mode is currently enabled.
    ///
    /// - Returns: `true` if shuffle is enabled, `false` if disabled.
    /// - Throws: ``MusicError/musicNotRunning`` if Music.app is not running.
    func getShuffle() throws -> Bool

    /// Sets the shuffle state.
    ///
    /// Enables or disables shuffle mode for playback.
    ///
    /// - Parameter enabled: `true` to enable shuffle, `false` to disable.
    /// - Throws: ``MusicError/musicNotRunning`` if Music.app is not running.
    func setShuffle(_ enabled: Bool) throws

    /// Gets the current repeat mode.
    ///
    /// Returns the active repeat mode setting.
    ///
    /// - Returns: Current ``RepeatMode`` (off, one, or all).
    /// - Throws: ``MusicError/musicNotRunning`` if Music.app is not running.
    func getRepeatMode() throws -> RepeatMode

    /// Sets the repeat mode.
    ///
    /// Changes the repeat mode for playback.
    ///
    /// - Parameter mode: ``RepeatMode`` to set (off = no repeat, one = repeat current track, all = repeat playlist).
    /// - Throws: ``MusicError/musicNotRunning`` if Music.app is not running.
    ///
    /// ## Example
    ///
    /// ```swift
    /// try service.setRepeatMode(.one) // Repeat current track
    /// ```
    func setRepeatMode(_ mode: RepeatMode) throws

    // MARK: - Playback Controls

    /// Plays a specific playlist.
    ///
    /// Starts playback of the specified playlist from the beginning.
    ///
    /// - Parameter name: Name of the playlist to play (case-sensitive).
    /// - Throws:
    ///   - ``MusicError/musicNotRunning`` if Music.app is not running.
    ///   - ``MusicError/playlistNotFound(_:)`` if playlist doesn't exist.
    ///
    /// ## Example
    ///
    /// ```swift
    /// try service.playPlaylist("Workout Mix")
    /// ```
    func playPlaylist(_ name: String) throws

    /// Plays a specific track by searching for it.
    ///
    /// Searches for and plays the first track matching the query.
    ///
    /// - Parameter query: Search query to find the track.
    /// - Throws:
    ///   - ``MusicError/musicNotRunning`` if Music.app is not running.
    ///   - ``MusicError/trackNotFound(_:)`` if no matching track found.
    func playTrack(_ query: String) throws

    /// Adds a track to play next in the queue.
    ///
    /// Searches for a track and adds it to play immediately after the current track.
    ///
    /// - Parameter query: Search query to find the track.
    /// - Throws:
    ///   - ``MusicError/musicNotRunning`` if Music.app is not running.
    ///   - ``MusicError/trackNotFound(_:)`` if no matching track found.
    ///
    /// ## Example
    ///
    /// ```swift
    /// try service.playNext("Bohemian Rhapsody")
    /// ```
    func playNext(_ query: String) throws
}
