import Foundation

public struct PodcastsService: PodcastsServiceProtocol {
    private var appleScript: any AppleScriptRunnerProtocol { Services.appleScriptRunner() }

    public init() {}

    public func listShows() throws -> [PodcastShow] {
        let script = """
        tell application "Podcasts"
            set showList to {}
            repeat with s in shows
                set showName to name of s
                set epCount to count of episodes of s
                set auth to ""
                try
                    set auth to artist of s
                end try
                set end of showList to showName & "|||" & (epCount as text) & "|||" & auth
            end repeat
            return showList
        end tell
        """

        let result = try appleScript.run(script, identifier: "podcasts-shows")
        guard !result.isEmpty else { return [] }

        return result.split(separator: ",").compactMap { item in
            let trimmed = item.trimmingCharacters(in: .whitespacesAndNewlines)
            let parts = trimmed.split(separator: "|||", maxSplits: 2).map { $0.trimmingCharacters(in: .whitespaces) }
            guard !parts.isEmpty else { return nil }
            let name = parts[0]
            let count = parts.count > 1 ? Int(parts[1]) ?? 0 : 0
            let author = parts.count > 2 && !parts[2].isEmpty ? parts[2] : nil
            return PodcastShow(name: name, episodeCount: count, author: author)
        }
    }

    public func listEpisodes(showName: String) throws -> [PodcastEpisode] {
        let safeName = showName.replacingOccurrences(of: "\"", with: "\\\"")
        let script = """
        tell application "Podcasts"
            set theShow to first show whose name is "\(safeName)"
            set epList to {}
            set maxEps to 20
            set counter to 0
            repeat with ep in episodes of theShow
                if counter ≥ maxEps then exit repeat
                set epTitle to title of ep
                set epDate to ""
                try
                    set epDate to (release date of ep) as text
                end try
                set end of epList to epTitle & "|||" & epDate
                set counter to counter + 1
            end repeat
            return epList
        end tell
        """

        let result = try appleScript.run(script, identifier: "podcasts-episodes")
        guard !result.isEmpty else { return [] }

        return result.split(separator: ",").compactMap { item in
            let trimmed = item.trimmingCharacters(in: .whitespacesAndNewlines)
            let parts = trimmed.split(separator: "|||", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            guard !parts.isEmpty else { return nil }
            let title = parts[0]
            let date = parts.count > 1 && !parts[1].isEmpty ? parts[1] : nil
            return PodcastEpisode(title: title, showName: showName, date: date, duration: nil, played: nil)
        }
    }

    public func nowPlaying() throws -> PodcastEpisode? {
        let script = """
        tell application "Podcasts"
            if player state is playing then
                set currentTrack to current track
                set epTitle to title of currentTrack
                set epShow to ""
                try
                    set epShow to show of currentTrack
                end try
                return epTitle & "|||" & epShow
            else
                return ""
            end if
        end tell
        """

        let result = try appleScript.run(script, identifier: "podcasts-now-playing")
        guard !result.isEmpty else { return nil }

        let parts = result.split(separator: "|||", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
        let title = parts[0]
        let showName = parts.count > 1 && !parts[1].isEmpty ? parts[1] : nil
        return PodcastEpisode(title: title, showName: showName, date: nil, duration: nil, played: nil)
    }

    public func play() throws {
        _ = try appleScript.run("tell application \"Podcasts\" to play", identifier: "podcasts-play")
    }

    public func pause() throws {
        _ = try appleScript.run("tell application \"Podcasts\" to pause", identifier: "podcasts-pause")
    }

    public func playEpisode(title: String) throws {
        let safeTitle = title.replacingOccurrences(of: "\"", with: "\\\"")
        let script = """
        tell application "Podcasts"
            set allEps to every episode of every show
            repeat with epList in allEps
                repeat with ep in epList
                    if title of ep is "\(safeTitle)" then
                        play ep
                        return "playing"
                    end if
                end repeat
            end repeat
            return "not found"
        end tell
        """
        let result = try appleScript.run(script, identifier: "podcasts-play-episode")
        if result.contains("not found") {
            throw PodcastsError.episodeNotFound(title)
        }
    }
}

public enum PodcastsError: LocalizedError {
    case episodeNotFound(String)
    case showNotFound(String)

    public var errorDescription: String? {
        switch self {
        case .episodeNotFound(let title):
            return "Episode not found: \(title)"
        case .showNotFound(let name):
            return "Show not found: \(name)"
        }
    }
}
