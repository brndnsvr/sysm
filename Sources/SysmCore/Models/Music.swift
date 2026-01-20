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
    public let shuffle: Bool?
    public let repeatMode: String?
    public let volume: Int?

    public init(name: String, artist: String, album: String, duration: Int, position: Int, state: String,
                shuffle: Bool? = nil, repeatMode: String? = nil, volume: Int? = nil) {
        self.name = name
        self.artist = artist
        self.album = album
        self.duration = duration
        self.position = position
        self.state = state
        self.shuffle = shuffle
        self.repeatMode = repeatMode
        self.volume = volume
    }

    public func formatted() -> String {
        let progress = duration > 0 ? "\(formatTime(position)) / \(formatTime(duration))" : ""
        var result = """
        \(name)
        Artist: \(artist)
        Album: \(album)
        State: \(state.capitalized)
        Progress: \(progress)
        """
        if let shuffle = shuffle {
            result += "\nShuffle: \(shuffle ? "On" : "Off")"
        }
        if let repeatMode = repeatMode {
            result += "\nRepeat: \(repeatMode.capitalized)"
        }
        if let volume = volume {
            result += "\nVolume: \(volume)%"
        }
        return result
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
