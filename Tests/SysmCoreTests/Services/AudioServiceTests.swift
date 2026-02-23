import XCTest
@testable import SysmCore

final class AudioServiceTests: XCTestCase {
    private var service: AudioService!

    override func setUp() {
        super.setUp()
        service = AudioService()
    }

    func testGetVolumeReturnsValidRange() throws {
        let info = try service.getVolume()
        XCTAssertGreaterThanOrEqual(info.volume, 0)
        XCTAssertLessThanOrEqual(info.volume, 100)
    }

    func testListDevicesReturnsNonEmpty() throws {
        let devices = try service.listDevices()
        // Every Mac has at least a built-in audio device
        XCTAssertFalse(devices.isEmpty)
    }

    func testGetDefaultOutputReturnsValidDevice() throws {
        let device = try service.getDefaultOutput()
        XCTAssertFalse(device.name.isEmpty)
        XCTAssertFalse(device.isInput)
    }

    func testGetDefaultInputReturnsValidDevice() throws {
        let device = try service.getDefaultInput()
        XCTAssertFalse(device.name.isEmpty)
        XCTAssertTrue(device.isInput)
    }

    func testVolumeOutOfRangeThrows() {
        XCTAssertThrowsError(try service.setVolume(101)) { error in
            guard case AudioError.volumeOutOfRange = error else {
                XCTFail("Expected volumeOutOfRange, got \(error)")
                return
            }
        }
        XCTAssertThrowsError(try service.setVolume(-1)) { error in
            guard case AudioError.volumeOutOfRange = error else {
                XCTFail("Expected volumeOutOfRange, got \(error)")
                return
            }
        }
    }

    func testDeviceNotFoundThrows() {
        XCTAssertThrowsError(try service.setDefaultOutput(name: "NonExistentDevice12345")) { error in
            guard case AudioError.deviceNotFound = error else {
                XCTFail("Expected deviceNotFound, got \(error)")
                return
            }
        }
    }

    func testErrorDescriptions() {
        let errors: [(AudioError, String)] = [
            (.deviceNotFound("Test"), "Audio device not found: Test"),
            (.volumeOutOfRange(150), "Volume 150 out of range (must be 0-100)"),
            (.propertyReadFailed("volume", -1), "Failed to read volume (status: -1)"),
            (.propertyWriteFailed("mute", -1), "Failed to write mute (status: -1)"),
        ]
        for (error, expected) in errors {
            XCTAssertEqual(error.errorDescription, expected)
        }
    }
}
