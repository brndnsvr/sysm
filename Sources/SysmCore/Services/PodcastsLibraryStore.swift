import Foundation

struct PodcastLibraryEpisode: Sendable, Equatable {
    let title: String
    let url: URL?
}

protocol PodcastsLibraryProtocol: Sendable {
    func listShows() throws -> [PodcastShow]
    func listEpisodes(showName: String, limit: Int) throws -> [PodcastEpisode]
    func episode(matchingTitle title: String) throws -> PodcastLibraryEpisode?
    func currentEpisode() throws -> PodcastEpisode?
}

struct PodcastsLibraryStore: PodcastsLibraryProtocol {
    private let databaseURL: URL?

    init(databaseURL: URL? = nil) {
        self.databaseURL = databaseURL
    }

    func listShows() throws -> [PodcastShow] {
        let rows: [ShowRow] = try query("""
        SELECT
            p.Z_PK AS id,
            p.ZTITLE AS name,
            p.ZAUTHOR AS author,
            COUNT(e.Z_PK) AS episodeCount
        FROM ZMTPODCAST p
        LEFT JOIN ZMTEPISODE e
            ON e.ZPODCAST = p.Z_PK
            AND COALESCE(e.ZUSERDELETED, 0) = 0
            AND COALESCE(e.ZFEEDDELETED, 0) = 0
        WHERE p.ZSUBSCRIBED = 1
            AND COALESCE(p.ZHIDDEN, 0) = 0
        GROUP BY p.Z_PK
        ORDER BY p.ZTITLE COLLATE NOCASE;
        """)

        return rows.map {
            PodcastShow(name: $0.name, episodeCount: $0.episodeCount, author: $0.author)
        }
    }

    func listEpisodes(showName: String, limit: Int) throws -> [PodcastEpisode] {
        let shows: [ShowRow] = try query("""
        SELECT p.Z_PK AS id, p.ZTITLE AS name, p.ZAUTHOR AS author, 0 AS episodeCount
        FROM ZMTPODCAST p
        WHERE p.ZSUBSCRIBED = 1
            AND COALESCE(p.ZHIDDEN, 0) = 0;
        """)
        guard let show = shows.first(where: {
            $0.name.compare(showName, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }) else {
            throw PodcastsError.showNotFound(showName)
        }

        let safeLimit = max(1, min(limit, 500))
        let rows: [EpisodeRow] = try query("""
        SELECT
            e.ZTITLE AS title,
            p.ZTITLE AS showName,
            e.ZPUBDATE AS publishedAt,
            (SELECT MAX(m.ZDURATION) FROM ZMTMEDIAENCLOSURE m WHERE m.ZEPISODE = e.Z_PK) AS duration,
            CASE WHEN e.ZPLAYSTATE = 2 THEN 1 ELSE 0 END AS played,
            e.ZUUID AS identifier
        FROM ZMTEPISODE e
        JOIN ZMTPODCAST p ON p.Z_PK = e.ZPODCAST
        WHERE e.ZPODCAST = \(show.id)
            AND COALESCE(e.ZUSERDELETED, 0) = 0
            AND COALESCE(e.ZFEEDDELETED, 0) = 0
        ORDER BY e.ZPUBDATE DESC
        LIMIT \(safeLimit);
        """)

        return rows.map(episodeModel)
    }

    func episode(matchingTitle title: String) throws -> PodcastLibraryEpisode? {
        let encodedTitle = title.data(using: .utf8, allowLossyConversion: false)?
            .map { String(format: "%02x", $0) }
            .joined() ?? ""
        guard !encodedTitle.isEmpty else { return nil }

        let rows: [EpisodeIdentifierRow] = try query("""
        SELECT
            e.ZTITLE AS title,
            e.ZSTORETRACKID AS storeTrackID,
            p.ZSTORECLEANURL AS showURL
        FROM ZMTEPISODE e
        JOIN ZMTPODCAST p ON p.Z_PK = e.ZPODCAST
        WHERE e.ZTITLE = CAST(X'\(encodedTitle)' AS TEXT) COLLATE NOCASE
            AND COALESCE(e.ZUSERDELETED, 0) = 0
            AND COALESCE(e.ZFEEDDELETED, 0) = 0
        ORDER BY e.ZPUBDATE DESC
        LIMIT 1;
        """)

        guard let row = rows.first else { return nil }
        return PodcastLibraryEpisode(title: row.title, url: episodeURL(row))
    }

    func currentEpisode() throws -> PodcastEpisode? {
        let rows: [EpisodeRow] = try query("""
        SELECT
            e.ZTITLE AS title,
            p.ZTITLE AS showName,
            e.ZPUBDATE AS publishedAt,
            (SELECT MAX(m.ZDURATION) FROM ZMTMEDIAENCLOSURE m WHERE m.ZEPISODE = e.Z_PK) AS duration,
            CASE WHEN e.ZPLAYSTATE = 2 THEN 1 ELSE 0 END AS played,
            e.ZUUID AS identifier
        FROM ZMTEPISODE e
        JOIN ZMTPODCAST p ON p.Z_PK = e.ZPODCAST
        WHERE e.ZLASTDATEPLAYED IS NOT NULL
        ORDER BY e.ZLASTDATEPLAYED DESC
        LIMIT 1;
        """)
        return rows.first.map(episodeModel)
    }

    private func episodeModel(_ row: EpisodeRow) -> PodcastEpisode {
        let date = row.publishedAt.map {
            ISO8601DateFormatter().string(from: Date(timeIntervalSinceReferenceDate: $0))
        }
        let duration = row.duration.flatMap { $0 > 0 ? OutputFormatter.formatDuration($0) : nil }
        let played = row.played.map { $0 != 0 }
        return PodcastEpisode(
            title: row.title,
            showName: row.showName,
            date: date,
            duration: duration,
            played: played
        )
    }

    private func episodeURL(_ row: EpisodeIdentifierRow) -> URL? {
        guard let showURL = row.showURL,
              let storeTrackID = row.storeTrackID,
              storeTrackID > 0,
              var components = URLComponents(string: showURL) else {
            return nil
        }
        var queryItems = components.queryItems ?? []
        queryItems.removeAll { $0.name == "i" }
        queryItems.append(URLQueryItem(name: "i", value: String(storeTrackID)))
        components.queryItems = queryItems
        return components.url
    }

    private func query<T: Decodable>(_ sql: String) throws -> [T] {
        let url = try resolvedDatabaseURL()
        let output: String
        do {
            output = try Shell.run(
                "/usr/bin/sqlite3",
                args: ["-readonly", "-json", url.path, sql],
                timeout: 15
            )
        } catch {
            throw PodcastsError.databaseReadFailed(error.localizedDescription)
        }

        guard !output.isEmpty else { return [] }
        do {
            return try JSONDecoder().decode([T].self, from: Data(output.utf8))
        } catch {
            throw PodcastsError.invalidLibraryData(error.localizedDescription)
        }
    }

    private func resolvedDatabaseURL() throws -> URL {
        if let databaseURL, FileManager.default.fileExists(atPath: databaseURL.path) {
            return databaseURL
        }

        let home = FileManager.default.homeDirectoryForCurrentUser
        let knownCandidates = [
            home.appendingPathComponent("Library/Group Containers/243LU875E5.groups.com.apple.podcasts/Documents/MTLibrary.sqlite"),
            home.appendingPathComponent("Library/Containers/com.apple.podcasts/Data/Documents/MTLibrary.sqlite"),
        ]
        if let match = knownCandidates.first(where: { FileManager.default.fileExists(atPath: $0.path) }) {
            return match
        }

        let groupContainers = home.appendingPathComponent("Library/Group Containers")
        if let entries = try? FileManager.default.contentsOfDirectory(
            at: groupContainers,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) {
            for entry in entries where entry.lastPathComponent.hasSuffix("groups.com.apple.podcasts") {
                let candidate = entry.appendingPathComponent("Documents/MTLibrary.sqlite")
                if FileManager.default.fileExists(atPath: candidate.path) {
                    return candidate
                }
            }
        }

        throw PodcastsError.libraryUnavailable
    }
}

private struct ShowRow: Decodable {
    let id: Int
    let name: String
    let author: String?
    let episodeCount: Int
}

private struct EpisodeRow: Decodable {
    let title: String
    let showName: String?
    let publishedAt: TimeInterval?
    let duration: TimeInterval?
    let played: Int?
    let identifier: String?
}

private struct EpisodeIdentifierRow: Decodable {
    let title: String
    let storeTrackID: Int64?
    let showURL: String?
}
