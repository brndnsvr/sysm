import XCTest

final class MediaIntegrationTests: IntegrationTestCase {

    // MARK: - Helpers

    /// Run a command or skip if the backing app isn't running / accessible.
    private func runOrSkipMedia(_ args: [String], timeout: TimeInterval = 30, reason: String) throws -> String {
        do {
            return try runCommand(args, timeout: timeout)
        } catch IntegrationTestError.commandFailed(_, _, let stderr) {
            if stderr.localizedCaseInsensitiveContains("not running") ||
               stderr.localizedCaseInsensitiveContains("not open") ||
               stderr.localizedCaseInsensitiveContains("error") ||
               stderr.localizedCaseInsensitiveContains("connection") ||
               stderr.localizedCaseInsensitiveContains("applescript") {
                throw XCTSkip(reason)
            }
            throw IntegrationTestError.commandFailed(
                command: args.joined(separator: " "), exitCode: 1, stderr: stderr
            )
        } catch IntegrationTestError.timeout {
            throw XCTSkip("\(reason) (timed out)")
        }
    }

    // MARK: - Music

    func testMusicStatus() throws {
        let output = try runOrSkipMedia(
            ["music", "status", "--json"],
            reason: "Music app not running"
        )
        let data = try XCTUnwrap(output.data(using: .utf8))
        _ = try JSONSerialization.jsonObject(with: data)
    }

    func testMusicPlaylists() throws {
        let output = try runOrSkipMedia(
            ["music", "playlists", "--json"],
            reason: "Music app not running"
        )
        let data = try XCTUnwrap(output.data(using: .utf8))
        _ = try JSONSerialization.jsonObject(with: data)
    }

    // MARK: - Podcasts

    func testPodcastsShows() throws {
        let output = try runOrSkipMedia(
            ["podcasts", "shows", "--json"],
            reason: "Podcasts app not running"
        )
        let data = try XCTUnwrap(output.data(using: .utf8))
        _ = try JSONSerialization.jsonObject(with: data)
    }

    // MARK: - Books

    func testBooksCollections() throws {
        let output = try runOrSkipMedia(
            ["books", "collections", "--json"],
            timeout: 60,
            reason: "Books app not running"
        )
        let data = try XCTUnwrap(output.data(using: .utf8))
        _ = try JSONSerialization.jsonObject(with: data)
    }

    func testBooksList() throws {
        let output = try runOrSkipMedia(
            ["books", "list", "--json"],
            timeout: 60,
            reason: "Books app not running"
        )
        let data = try XCTUnwrap(output.data(using: .utf8))
        _ = try JSONSerialization.jsonObject(with: data)
    }

    // MARK: - Speak

    func testSpeakVoices() throws {
        let output = try runCommand(["speak", "voices", "--json"])
        let data = try XCTUnwrap(output.data(using: .utf8))
        let arr = try JSONSerialization.jsonObject(with: data)

        XCTAssertTrue(arr is [Any], "Expected JSON array of voices")
        if let voices = arr as? [Any] {
            XCTAssertFalse(voices.isEmpty, "Should have at least one voice available")
        }
    }
}
