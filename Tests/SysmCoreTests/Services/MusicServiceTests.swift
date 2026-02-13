//
//  MusicServiceTests.swift
//  sysm
//

import XCTest
@testable import SysmCore

final class MusicServiceTests: XCTestCase {
    var mockRunner: MockAppleScriptRunner!
    var service: MusicService!

    override func setUp() {
        super.setUp()
        mockRunner = MockAppleScriptRunner()
        service = MusicService(scriptRunner: mockRunner)
    }

    override func tearDown() {
        mockRunner = nil
        service = nil
        super.tearDown()
    }

    // MARK: - Playback Control Tests

    func testPlay() throws {
        mockRunner.mockResponses["music-play"] = "success"

        XCTAssertNoThrow(try service.play())

        let script = mockRunner.lastScript!
        XCTAssertTrue(script.contains("play"))
    }

    func testPause() throws {
        mockRunner.mockResponses["music-pause"] = "success"

        XCTAssertNoThrow(try service.pause())

        let script = mockRunner.lastScript!
        XCTAssertTrue(script.contains("pause"))
    }

    func testStop() throws {
        mockRunner.mockResponses["music-stop"] = "success"

        XCTAssertNoThrow(try service.stop())

        let script = mockRunner.lastScript!
        XCTAssertTrue(script.contains("stop"))
    }

    func testNext() throws {
        mockRunner.mockResponses["music-next"] = "success"

        XCTAssertNoThrow(try service.nextTrack())

        let script = mockRunner.lastScript!
        XCTAssertTrue(script.contains("next"))
    }

    func testPrevious() throws {
        mockRunner.mockResponses["music-previous"] = "success"

        XCTAssertNoThrow(try service.previousTrack())

        let script = mockRunner.lastScript!
        XCTAssertTrue(script.contains("previous") || script.contains("back"))
    }

    // MARK: - Volume Tests

    func testSetVolume() throws {
        mockRunner.mockResponses["music-volume"] = "success"

        XCTAssertNoThrow(try service.setVolume(50))

        let script = mockRunner.lastScript!
        XCTAssertTrue(script.contains("50") || script.contains("volume"))
    }

    func testSetVolumeMax() throws {
        mockRunner.mockResponses["music-volume"] = "success"

        XCTAssertNoThrow(try service.setVolume(100))

        let script = mockRunner.lastScript!
        XCTAssertTrue(script.contains("100"))
    }

    func testSetVolumeMin() throws {
        mockRunner.mockResponses["music-volume"] = "success"

        XCTAssertNoThrow(try service.setVolume(0))

        let script = mockRunner.lastScript!
        XCTAssertTrue(script.contains("0"))
    }

    func testSetVolumeInvalid() {
        XCTAssertThrowsError(try service.setVolume(150)) { error in
            XCTAssertTrue(error is MusicError)
            if case MusicError.invalidVolume = error {
                // Expected
            } else {
                XCTFail("Wrong error type")
            }
        }

        XCTAssertThrowsError(try service.setVolume(-10)) { error in
            XCTAssertTrue(error is MusicError)
        }
    }

    // MARK: - Status Tests

    func testGetStatus() throws {
        let mockOutput = "playing|||Song Title|||Artist Name|||Album Name|||3:45|||1:30"
        mockRunner.mockResponses["music-status"] = mockOutput

        let status = try service.getStatus()

        XCTAssertNotNil(status)
        XCTAssertTrue(status.contains("Song Title") || status.contains("playing"))
    }

    func testGetStatusNotPlaying() {
        mockRunner.mockErrors["music-status"] = MusicError.notPlaying

        XCTAssertThrowsError(try service.getStatus()) { error in
            XCTAssertTrue(error is MusicError)
            if case MusicError.notPlaying = error {
                // Expected
            } else {
                XCTFail("Wrong error type")
            }
        }
    }

    // MARK: - Shuffle and Repeat Tests

    func testSetShuffle() throws {
        mockRunner.mockResponses["music-shuffle"] = "success"

        XCTAssertNoThrow(try service.setShuffle(true))

        let script = mockRunner.lastScript!
        XCTAssertTrue(script.contains("shuffle"))
    }

    func testSetRepeat() throws {
        mockRunner.mockResponses["music-repeat"] = "success"

        XCTAssertNoThrow(try service.setRepeat(enabled: true))

        let script = mockRunner.lastScript!
        XCTAssertTrue(script.contains("repeat"))
    }

    // MARK: - Error Tests

    func testMusicNotRunning() {
        mockRunner.mockErrors["music-play"] = MusicError.musicNotRunning

        XCTAssertThrowsError(try service.play()) { error in
            XCTAssertTrue(error is MusicError)
            if case MusicError.musicNotRunning = error {
                // Expected
            } else {
                XCTFail("Wrong error type")
            }
        }
    }

    // MARK: - Script Generation Tests

    func testScriptGenerationForPlayback() throws {
        mockRunner.mockResponses["music-play"] = "success"

        _ = try service.play()

        let script = mockRunner.lastScript!
        XCTAssertTrue(script.contains("tell application \"Music\""))
    }
}
