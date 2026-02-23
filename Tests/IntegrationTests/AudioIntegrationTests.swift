import XCTest

final class AudioIntegrationTests: IntegrationTestCase {

    // MARK: - Help

    func testAudioHelp() throws {
        let output = try runCommand(["audio", "--help"])

        XCTAssertTrue(output.contains("devices"))
        XCTAssertTrue(output.contains("volume"))
        XCTAssertTrue(output.contains("output"))
        XCTAssertTrue(output.contains("input"))
        XCTAssertTrue(output.contains("mute"))
        XCTAssertTrue(output.contains("unmute"))
    }

    // MARK: - Read-Only Queries

    func testAudioDevices() throws {
        let output = try runCommand(["audio", "devices", "--json"])
        let data = try XCTUnwrap(output.data(using: .utf8))
        let devices = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]

        let arr = try XCTUnwrap(devices, "Expected JSON array of devices")
        XCTAssertFalse(arr.isEmpty, "Should have at least one audio device")
        for device in arr {
            XCTAssertNotNil(device["name"], "Each device should have a name")
        }
    }

    func testAudioVolume() throws {
        let output = try runCommand(["audio", "volume", "--json"])
        let data = try XCTUnwrap(output.data(using: .utf8))
        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        let dict = try XCTUnwrap(obj, "Expected JSON object")
        let volume = try XCTUnwrap(dict["volume"] as? Int, "Should have volume field")
        XCTAssertTrue(volume >= 0 && volume <= 100, "Volume should be 0-100, got \(volume)")
        XCTAssertNotNil(dict["isMuted"], "Should have isMuted field")
    }

    func testAudioOutput() throws {
        let output = try runCommand(["audio", "output", "--json"])
        let data = try XCTUnwrap(output.data(using: .utf8))
        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        let dict = try XCTUnwrap(obj, "Expected JSON object")
        XCTAssertNotNil(dict["name"], "Output device should have a name")
    }

    func testAudioInput() throws {
        let output = try runCommand(["audio", "input", "--json"])
        let data = try XCTUnwrap(output.data(using: .utf8))
        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        let dict = try XCTUnwrap(obj, "Expected JSON object")
        XCTAssertNotNil(dict["name"], "Input device should have a name")
    }

    // MARK: - Volume Round-Trip

    func testAudioVolumeRoundTrip() throws {
        // Read current volume
        let originalOutput = try runCommand(["audio", "volume", "--json"])
        let originalData = try XCTUnwrap(originalOutput.data(using: .utf8))
        let originalObj = try XCTUnwrap(
            JSONSerialization.jsonObject(with: originalData) as? [String: Any]
        )
        let originalVolume = try XCTUnwrap(originalObj["volume"] as? Int)

        defer {
            // Restore original volume
            try? runCommand(["audio", "volume", "set", "\(originalVolume)"])
        }

        // Set to 42
        _ = try runCommand(["audio", "volume", "set", "42"])

        // Verify
        let verifyOutput = try runCommand(["audio", "volume", "--json"])
        let verifyData = try XCTUnwrap(verifyOutput.data(using: .utf8))
        let verifyObj = try XCTUnwrap(
            JSONSerialization.jsonObject(with: verifyData) as? [String: Any]
        )
        let newVolume = try XCTUnwrap(verifyObj["volume"] as? Int)
        XCTAssertEqual(newVolume, 42, "Volume should be 42 after setting")
    }

    // MARK: - Mute/Unmute

    func testAudioMuteUnmute() throws {
        // Read current state
        let originalOutput = try runCommand(["audio", "volume", "--json"])
        let originalData = try XCTUnwrap(originalOutput.data(using: .utf8))
        let originalObj = try XCTUnwrap(
            JSONSerialization.jsonObject(with: originalData) as? [String: Any]
        )
        let wasMuted = (originalObj["isMuted"] as? Bool) ?? false

        defer {
            // Restore original state
            if wasMuted {
                try? runCommand(["audio", "mute"])
            } else {
                try? runCommand(["audio", "unmute"])
            }
        }

        // Mute
        _ = try runCommand(["audio", "mute"])
        let mutedOutput = try runCommand(["audio", "volume", "--json"])
        let mutedData = try XCTUnwrap(mutedOutput.data(using: .utf8))
        let mutedObj = try XCTUnwrap(
            JSONSerialization.jsonObject(with: mutedData) as? [String: Any]
        )
        XCTAssertEqual(mutedObj["isMuted"] as? Bool, true, "Should be muted after mute")

        // Unmute
        _ = try runCommand(["audio", "unmute"])
        let unmutedOutput = try runCommand(["audio", "volume", "--json"])
        let unmutedData = try XCTUnwrap(unmutedOutput.data(using: .utf8))
        let unmutedObj = try XCTUnwrap(
            JSONSerialization.jsonObject(with: unmutedData) as? [String: Any]
        )
        XCTAssertEqual(unmutedObj["isMuted"] as? Bool, false, "Should be unmuted after unmute")
    }
}
