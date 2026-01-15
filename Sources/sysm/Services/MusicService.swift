import Foundation

struct MusicService: MusicServiceProtocol {

    // MARK: - Models

    struct NowPlaying: Codable {
        let name: String
        let artist: String
        let album: String
        let duration: Int  // seconds
        let position: Int  // seconds
        let state: String  // playing, paused, stopped

        func formatted() -> String {
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

    struct Playlist: Codable {
        let name: String
        let trackCount: Int
        let duration: Int  // seconds

        func formatted() -> String {
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

    struct Track: Codable {
        let name: String
        let artist: String
        let album: String
        let duration: Int

        func formatted() -> String {
            let durationStr = formatTime(duration)
            return "\(name) - \(artist) [\(durationStr)]"
        }

        private func formatTime(_ seconds: Int) -> String {
            let mins = seconds / 60
            let secs = seconds % 60
            return String(format: "%d:%02d", mins, secs)
        }
    }

    // MARK: - Playback Control

    func play() throws {
        let script = """
        tell application "Music"
            play
        end tell
        """
        _ = try runAppleScript(script)
    }

    func pause() throws {
        let script = """
        tell application "Music"
            pause
        end tell
        """
        _ = try runAppleScript(script)
    }

    func nextTrack() throws {
        let script = """
        tell application "Music"
            next track
        end tell
        """
        _ = try runAppleScript(script)
    }

    func previousTrack() throws {
        let script = """
        tell application "Music"
            previous track
        end tell
        """
        _ = try runAppleScript(script)
    }

    func setVolume(_ level: Int) throws {
        guard level >= 0 && level <= 100 else {
            throw MusicError.invalidVolume(level)
        }
        let script = """
        tell application "Music"
            set sound volume to \(level)
        end tell
        """
        _ = try runAppleScript(script)
    }

    // MARK: - Now Playing

    func getStatus() throws -> NowPlaying? {
        let script = """
        tell application "Music"
            if player state is stopped then
                return "stopped|||||||0|||0"
            end if
            set trackName to name of current track
            set trackArtist to artist of current track
            set trackAlbum to album of current track
            set trackDuration to duration of current track
            set trackPosition to player position
            if player state is playing then
                set stateStr to "playing"
            else if player state is paused then
                set stateStr to "paused"
            else
                set stateStr to "stopped"
            end if
            return trackName & "|||" & trackArtist & "|||" & trackAlbum & "|||" & (trackDuration as integer) & "|||" & (trackPosition as integer) & "|||" & stateStr
        end tell
        """

        let result = try runAppleScript(script)
        let parts = result.components(separatedBy: "|||")
        guard parts.count >= 6 else { return nil }

        let name = parts[0]
        if name.isEmpty && parts[5] == "stopped" {
            return NowPlaying(name: "", artist: "", album: "", duration: 0, position: 0, state: "stopped")
        }

        return NowPlaying(
            name: parts[0],
            artist: parts[1],
            album: parts[2],
            duration: Int(parts[3]) ?? 0,
            position: Int(parts[4]) ?? 0,
            state: parts[5]
        )
    }

    // MARK: - Library

    func listPlaylists() throws -> [Playlist] {
        let script = """
        tell application "Music"
            set AppleScript's text item delimiters to "|||"
            set output to ""
            repeat with p in user playlists
                if output is not "" then set output to output & "###"
                set trackCount to count of tracks of p
                set output to output & (name of p) & "|||" & trackCount & "|||" & (duration of p)
            end repeat
            set AppleScript's text item delimiters to ""
            return output
        end tell
        """

        let result = try runAppleScript(script)
        if result.isEmpty { return [] }

        return result.components(separatedBy: "###").compactMap { item in
            let parts = item.components(separatedBy: "|||")
            guard parts.count >= 3 else { return nil }
            return Playlist(
                name: parts[0],
                trackCount: Int(parts[1]) ?? 0,
                duration: Int(Double(parts[2]) ?? 0)
            )
        }
    }

    func searchLibrary(query: String, limit: Int = 20) throws -> [Track] {
        let escapedQuery = AppleScriptRunner.escape(query)
        let script = """
        tell application "Music"
            set results to search library playlist 1 for "\(escapedQuery)"
            set output to ""
            set counter to 0
            repeat with t in results
                if counter >= \(limit) then exit repeat
                if output is not "" then set output to output & "###"
                set output to output & (name of t) & "|||" & (artist of t) & "|||" & (album of t) & "|||" & ((duration of t) as integer)
                set counter to counter + 1
            end repeat
            return output
        end tell
        """

        let result = try runAppleScript(script)
        if result.isEmpty { return [] }

        return result.components(separatedBy: "###").compactMap { item in
            let parts = item.components(separatedBy: "|||")
            guard parts.count >= 4 else { return nil }
            return Track(
                name: parts[0],
                artist: parts[1],
                album: parts[2],
                duration: Int(parts[3]) ?? 0
            )
        }
    }

    // MARK: - Private Helpers

    private func runAppleScript(_ script: String) throws -> String {
        let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent("sysm-music-\(UUID().uuidString).scpt")
        try script.write(to: tempFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempFile) }

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        task.arguments = [tempFile.path]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = errorPipe

        try task.run()
        task.waitUntilExit()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

        if task.terminationStatus != 0 {
            let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            // Check if Music.app is not running
            if errorMessage.contains("not running") {
                throw MusicError.musicNotRunning
            }
            throw MusicError.appleScriptError(errorMessage)
        }

        return String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}

enum MusicError: LocalizedError {
    case musicNotRunning
    case invalidVolume(Int)
    case appleScriptError(String)
    case notPlaying

    var errorDescription: String? {
        switch self {
        case .musicNotRunning:
            return "Music.app is not running. Launch it first."
        case .invalidVolume(let level):
            return "Invalid volume level: \(level). Use 0-100."
        case .appleScriptError(let message):
            return "Music error: \(message)"
        case .notPlaying:
            return "No track is currently playing"
        }
    }
}
