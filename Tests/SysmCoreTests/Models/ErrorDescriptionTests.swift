import XCTest
@testable import SysmCore

/// Tests that all domain error enums have non-nil errorDescription for every case.
final class ErrorDescriptionTests: XCTestCase {

    // MARK: - NotesError

    func testNotesErrorDescriptions() {
        let cases: [NotesError] = [
            .appleScriptError("test"),
            .noteNotFound("test"),
            .folderNotFound("test"),
            .exportFailed("test"),
        ]
        for error in cases {
            XCTAssertNotNil(error.errorDescription, "NotesError.\(error) should have errorDescription")
        }
    }

    // MARK: - SafariError

    func testSafariErrorDescriptions() {
        let cases: [SafariError] = [
            .bookmarksNotFound,
            .invalidPlist,
            .appleScriptError("test"),
            .safariNotRunning,
        ]
        for error in cases {
            XCTAssertNotNil(error.errorDescription, "SafariError.\(error) should have errorDescription")
        }
    }

    // MARK: - WeatherError

    func testWeatherErrorDescriptions() {
        let cases: [WeatherError] = [
            .locationNotFound("test"),
            .apiError("test"),
            .invalidResponse,
            .networkError("test"),
        ]
        for error in cases {
            XCTAssertNotNil(error.errorDescription, "WeatherError.\(error) should have errorDescription")
        }
    }

    // MARK: - WorkflowError

    func testWorkflowErrorDescriptions() {
        let cases: [WorkflowError] = [
            .fileNotFound("test.yml"),
            .parseError("bad yaml"),
            .stepFailed("step1", "reason"),
            .conditionFailed("cond"),
            .invalidTemplate("tmpl"),
            .timeout("step2"),
        ]
        for error in cases {
            XCTAssertNotNil(error.errorDescription, "WorkflowError.\(error) should have errorDescription")
        }
    }

    // MARK: - MusicError

    func testMusicErrorDescriptions() {
        let cases: [MusicError] = [
            .musicNotRunning,
            .invalidVolume(150),
            .appleScriptError("test"),
            .notPlaying,
        ]
        for error in cases {
            XCTAssertNotNil(error.errorDescription, "MusicError.\(error) should have errorDescription")
        }
    }

    func testMusicErrorRecoverySuggestions() {
        XCTAssertNotNil(MusicError.musicNotRunning.recoverySuggestion)
        XCTAssertNotNil(MusicError.invalidVolume(150).recoverySuggestion)
        XCTAssertNotNil(MusicError.appleScriptError("test").recoverySuggestion)
        XCTAssertNotNil(MusicError.notPlaying.recoverySuggestion)
    }

    // MARK: - MessagesError

    func testMessagesErrorDescriptions() {
        let cases: [MessagesError] = [
            .appleScriptError("test"),
            .messagesNotRunning,
            .sendFailed("reason"),
        ]
        for error in cases {
            XCTAssertNotNil(error.errorDescription, "MessagesError.\(error) should have errorDescription")
        }
    }

    func testMessagesErrorRecoverySuggestions() {
        XCTAssertNotNil(MessagesError.appleScriptError("test").recoverySuggestion)
        XCTAssertNotNil(MessagesError.messagesNotRunning.recoverySuggestion)
        XCTAssertNotNil(MessagesError.sendFailed("reason").recoverySuggestion)
    }

    // MARK: - SlackError

    func testSlackErrorDescriptions() {
        let cases: [SlackError] = [
            .notConfigured,
            .invalidToken,
            .apiError("test"),
            .channelNotFound("general"),
            .networkError("timeout"),
        ]
        for error in cases {
            XCTAssertNotNil(error.errorDescription, "SlackError.\(error) should have errorDescription")
        }
    }

    func testSlackErrorRecoverySuggestions() {
        XCTAssertNotNil(SlackError.notConfigured.recoverySuggestion)
        XCTAssertNotNil(SlackError.invalidToken.recoverySuggestion)
    }

    // MARK: - OutlookError

    func testOutlookErrorDescriptions() {
        let cases: [OutlookError] = [
            .outlookNotRunning,
            .outlookNotInstalled,
            .appleScriptError("test"),
            .messageNotFound("1"),
            .sendFailed("reason"),
            .noRecipientsSpecified,
        ]
        for error in cases {
            XCTAssertNotNil(error.errorDescription, "OutlookError.\(error) should have errorDescription")
        }
    }
}
