import Foundation

// MARK: - Music Models

/// Current playback state and track information.
public struct NowPlaying: Codable {
    public let name: String
    public let artist: String
    public let album: String
    public let duration: Int  // seconds
    public let position: Int  // seconds
    public let state: String  // playing, paused, stopped

    public func formatted() -> String {
        let progress = duration > 0 ? "\(formatTime(position)) / \(formatTime(duration))" : ""
        return """
        \(name)
        Artist: \(artist)
        Album: \(album)
        State: \(state.capitalized)
        Progress: \(progress)
        """
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

/// A music playlist with metadata.
public struct Playlist: Codable {
    public let name: String
    public let trackCount: Int
    public let duration: Int  // seconds

    public func formatted() -> String {
        let durationStr = formatDuration(duration)
        return "\(name) (\(trackCount) tracks, \(durationStr))"
    }

    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let mins = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }
}

/// A single music track.
public struct Track: Codable {
    public let name: String
    public let artist: String
    public let album: String
    public let duration: Int

    public func formatted() -> String {
        let durationStr = formatTime(duration)
        return "\(name) - \(artist) [\(durationStr)]"
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
