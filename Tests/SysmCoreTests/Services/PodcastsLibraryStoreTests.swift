import Foundation
import XCTest
@testable import SysmCore

final class PodcastsLibraryStoreTests: XCTestCase {
    private var temporaryDirectory: URL!
    private var databaseURL: URL!
    private var store: PodcastsLibraryStore!

    override func setUpWithError() throws {
        try super.setUpWithError()
        temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("sysm-podcasts-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        databaseURL = temporaryDirectory.appendingPathComponent("MTLibrary.sqlite")
        _ = try Shell.run("/usr/bin/sqlite3", args: [databaseURL.path, Self.fixtureSQL])
        store = PodcastsLibraryStore(databaseURL: databaseURL)
    }

    override func tearDownWithError() throws {
        if let temporaryDirectory {
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }
        try super.tearDownWithError()
    }

    func testListShowsPreservesPunctuationAndFiltersUnfollowedShows() throws {
        let shows = try store.listShows()

        XCTAssertEqual(shows.count, 1)
        XCTAssertEqual(shows[0].name, "A Show, Indeed")
        XCTAssertEqual(shows[0].author, "Host, Person")
        XCTAssertEqual(shows[0].episodeCount, 3)
    }

    func testListEpisodesReturnsNewestFirstWithMetadata() throws {
        let episodes = try store.listEpisodes(showName: "a show, indeed", limit: 2)

        XCTAssertEqual(episodes.count, 2)
        XCTAssertEqual(episodes[0].title, "A \"quote\", and apostrophe's")
        XCTAssertEqual(episodes[0].showName, "A Show, Indeed")
        XCTAssertEqual(episodes[0].date, "2026-05-09T06:13:20Z")
        XCTAssertEqual(episodes[0].duration, "1:01:01")
        XCTAssertEqual(episodes[0].played, true)
        XCTAssertEqual(episodes[1].played, false)
    }

    func testListEpisodesThrowsForUnknownShow() {
        XCTAssertThrowsError(try store.listEpisodes(showName: "Missing", limit: 20)) { error in
            guard case PodcastsError.showNotFound("Missing") = error else {
                XCTFail("Expected showNotFound, got \(error)")
                return
            }
        }
    }

    func testEpisodeLookupSafelyHandlesPunctuation() throws {
        let episode = try store.episode(matchingTitle: "A \"QUOTE\", and apostrophe's")

        XCTAssertEqual(
            episode,
            PodcastLibraryEpisode(
                title: "A \"quote\", and apostrophe's",
                url: URL(string: "https://podcasts.apple.com/show/id123?i=456")
            )
        )
    }

    func testCurrentEpisodeReturnsMostRecentlyPlayedLibraryItem() throws {
        let episode = try store.currentEpisode()

        XCTAssertEqual(episode?.title, "A \"quote\", and apostrophe's")
        XCTAssertEqual(episode?.showName, "A Show, Indeed")
        XCTAssertEqual(episode?.duration, "1:01:01")
        XCTAssertEqual(episode?.played, true)
    }

    private static let fixtureSQL = """
    CREATE TABLE ZMTPODCAST (
        Z_PK INTEGER PRIMARY KEY,
        ZTITLE TEXT,
        ZAUTHOR TEXT,
        ZSUBSCRIBED INTEGER,
        ZHIDDEN INTEGER,
        ZSTORECLEANURL TEXT
    );
    CREATE TABLE ZMTEPISODE (
        Z_PK INTEGER PRIMARY KEY,
        ZTITLE TEXT,
        ZPODCAST INTEGER,
        ZUSERDELETED INTEGER,
        ZFEEDDELETED INTEGER,
        ZPUBDATE REAL,
        ZPLAYSTATE INTEGER,
        ZUUID TEXT,
        ZSTORETRACKID INTEGER,
        ZLASTDATEPLAYED REAL
    );
    CREATE TABLE ZMTMEDIAENCLOSURE (
        Z_PK INTEGER PRIMARY KEY,
        ZEPISODE INTEGER,
        ZDURATION REAL
    );

    INSERT INTO ZMTPODCAST VALUES (1, 'A Show, Indeed', 'Host, Person', 1, 0, 'https://podcasts.apple.com/show/id123');
    INSERT INTO ZMTPODCAST VALUES (2, 'Not Followed', 'Someone', 0, 0, NULL);
    INSERT INTO ZMTPODCAST VALUES (3, 'Hidden Show', 'Someone', 1, 1, NULL);

    INSERT INTO ZMTEPISODE VALUES (10, 'Older Episode', 1, 0, 0, 790000000, 0, 'episode-old', 455, 790000100);
    INSERT INTO ZMTEPISODE VALUES (11, 'A "quote", and apostrophe''s', 1, 0, 0, 800000000, 2, 'episode-special', 456, 800000100);
    INSERT INTO ZMTEPISODE VALUES (12, 'Middle Episode', 1, 0, 0, 795000000, 0, 'episode-middle', 457, 795000100);
    INSERT INTO ZMTEPISODE VALUES (13, 'Deleted Episode', 1, 1, 0, 810000000, 0, 'episode-deleted', 458, NULL);
    INSERT INTO ZMTEPISODE VALUES (14, 'Other Show Episode', 2, 0, 0, 810000000, 0, 'episode-other', 459, NULL);

    INSERT INTO ZMTMEDIAENCLOSURE VALUES (20, 11, 0);
    INSERT INTO ZMTMEDIAENCLOSURE VALUES (21, 11, 3661);
    INSERT INTO ZMTMEDIAENCLOSURE VALUES (22, 12, 1800);
    """
}
