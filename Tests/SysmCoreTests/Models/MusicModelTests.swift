import XCTest
@testable import SysmCore

final class MusicModelTests: XCTestCase {

    // MARK: - NowPlaying.formatted()

    func testNowPlayingFormattedBasic() {
        let np = NowPlaying(
            name: "Bohemian Rhapsody",
            artist: "Queen",
            album: "A Night at the Opera",
            duration: 354,
            position: 90,
            state: "playing"
        )

        let output = np.formatted()
        XCTAssertTrue(output.contains("Bohemian Rhapsody"))
        XCTAssertTrue(output.contains("Artist: Queen"))
        XCTAssertTrue(output.contains("Album: A Night at the Opera"))
        XCTAssertTrue(output.contains("State: Playing"))
        XCTAssertTrue(output.contains("1:30 / 5:54"))
    }

    func testNowPlayingFormattedWithExtras() {
        let np = NowPlaying(
            name: "Test Song",
            artist: "Test Artist",
            album: "Test Album",
            duration: 200,
            position: 100,
            state: "paused",
            shuffle: true,
            repeatMode: "all",
            volume: 75
        )

        let output = np.formatted()
        XCTAssertTrue(output.contains("Shuffle: On"))
        XCTAssertTrue(output.contains("Repeat: All"))
        XCTAssertTrue(output.contains("Volume: 75%"))
    }

    func testNowPlayingFormattedShuffleOff() {
        let np = NowPlaying(
            name: "Test", artist: "Artist", album: "Album",
            duration: 100, position: 50, state: "playing",
            shuffle: false
        )

        let output = np.formatted()
        XCTAssertTrue(output.contains("Shuffle: Off"))
    }

    // MARK: - formatTime (via NowPlaying)

    func testFormatTimeStandard() {
        let np = NowPlaying(
            name: "Test", artist: "Artist", album: "Album",
            duration: 90, position: 0, state: "playing"
        )
        let output = np.formatted()
        XCTAssertTrue(output.contains("0:00 / 1:30"))
    }

    func testFormatTimeLong() {
        let np = NowPlaying(
            name: "Test", artist: "Artist", album: "Album",
            duration: 3661, position: 3661, state: "playing"
        )
        let output = np.formatted()
        XCTAssertTrue(output.contains("61:01"))
    }

    func testFormatTimeZero() {
        let np = NowPlaying(
            name: "Test", artist: "Artist", album: "Album",
            duration: 0, position: 0, state: "stopped"
        )
        let output = np.formatted()
        // duration is 0 so progress is empty
        XCTAssertTrue(output.contains("Progress:"))
    }

    // MARK: - Playlist.formatted()

    func testPlaylistFormatted() {
        let playlist = Playlist(name: "Favorites", trackCount: 42, duration: 7200)
        let output = playlist.formatted()
        XCTAssertEqual(output, "Favorites (42 tracks, 2h 0m)")
    }

    func testPlaylistFormattedMinutesOnly() {
        let playlist = Playlist(name: "Short", trackCount: 5, duration: 300)
        let output = playlist.formatted()
        XCTAssertEqual(output, "Short (5 tracks, 5m)")
    }

    func testPlaylistFormattedWithMinuteRemainder() {
        let playlist = Playlist(name: "Mix", trackCount: 10, duration: 3720)
        let output = playlist.formatted()
        XCTAssertEqual(output, "Mix (10 tracks, 1h 2m)")
    }

    // MARK: - Track.formatted()

    func testTrackFormatted() {
        let track = Track(name: "Yesterday", artist: "The Beatles", album: "Help!", duration: 125)
        let output = track.formatted()
        XCTAssertEqual(output, "Yesterday - The Beatles [2:05]")
    }

    // MARK: - Codable Round-trips

    func testNowPlayingCodableRoundTrip() throws {
        let original = NowPlaying(
            name: "Song", artist: "Artist", album: "Album",
            duration: 200, position: 100, state: "playing",
            shuffle: true, repeatMode: "one", volume: 50
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(NowPlaying.self, from: data)
        XCTAssertEqual(original.name, decoded.name)
        XCTAssertEqual(original.shuffle, decoded.shuffle)
        XCTAssertEqual(original.repeatMode, decoded.repeatMode)
        XCTAssertEqual(original.volume, decoded.volume)
    }

    func testPlaylistCodableRoundTrip() throws {
        let original = Playlist(name: "Rock", trackCount: 50, duration: 10800)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Playlist.self, from: data)
        XCTAssertEqual(original.name, decoded.name)
        XCTAssertEqual(original.trackCount, decoded.trackCount)
        XCTAssertEqual(original.duration, decoded.duration)
    }

    func testTrackCodableRoundTrip() throws {
        let original = Track(name: "Song", artist: "Artist", album: "Album", duration: 180)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Track.self, from: data)
        XCTAssertEqual(original.name, decoded.name)
        XCTAssertEqual(original.artist, decoded.artist)
    }
}
