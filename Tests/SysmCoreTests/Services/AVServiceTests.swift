import XCTest
@testable import SysmCore

final class AVServiceTests: XCTestCase {
    private var service: AVService!

    override func setUp() {
        super.setUp()
        service = AVService()
    }

    // MARK: - Model Codable Round-Trips

    func testAVInputDeviceCodable() throws {
        let device = AVInputDevice(id: "device-1", name: "Built-in Microphone", isDefault: true)
        let data = try JSONEncoder().encode(device)
        let decoded = try JSONDecoder().decode(AVInputDevice.self, from: data)
        XCTAssertEqual(decoded.id, "device-1")
        XCTAssertEqual(decoded.name, "Built-in Microphone")
        XCTAssertTrue(decoded.isDefault)
    }

    func testAVFormatInfoCodable() throws {
        let info = AVFormatInfo(format: "m4a", fileExtension: "m4a", displayName: "AAC (M4A)")
        let data = try JSONEncoder().encode(info)
        let decoded = try JSONDecoder().decode(AVFormatInfo.self, from: data)
        XCTAssertEqual(decoded.format, "m4a")
        XCTAssertEqual(decoded.fileExtension, "m4a")
        XCTAssertEqual(decoded.displayName, "AAC (M4A)")
    }

    func testAVRecordingResultCodable() throws {
        let result = AVRecordingResult(path: "/tmp/recording.m4a", format: "m4a", duration: 10.5, fileSize: 102400)
        let data = try JSONEncoder().encode(result)
        let decoded = try JSONDecoder().decode(AVRecordingResult.self, from: data)
        XCTAssertEqual(decoded.path, "/tmp/recording.m4a")
        XCTAssertEqual(decoded.format, "m4a")
        XCTAssertEqual(decoded.duration, 10.5)
        XCTAssertEqual(decoded.fileSize, 102400)
    }

    func testAVTranscriptionSegmentCodable() throws {
        let segment = AVTranscriptionSegment(text: "Hello world", timestamp: 1.5, duration: 0.8, confidence: 0.95)
        let data = try JSONEncoder().encode(segment)
        let decoded = try JSONDecoder().decode(AVTranscriptionSegment.self, from: data)
        XCTAssertEqual(decoded.text, "Hello world")
        XCTAssertEqual(decoded.timestamp, 1.5)
        XCTAssertEqual(decoded.duration, 0.8)
        XCTAssertEqual(decoded.confidence, 0.95)
    }

    func testAVTranscriptionResultCodable() throws {
        let segments = [
            AVTranscriptionSegment(text: "Hello", timestamp: 0.0, duration: 0.5, confidence: 0.9),
            AVTranscriptionSegment(text: "world", timestamp: 0.5, duration: 0.5, confidence: 0.85),
        ]
        let result = AVTranscriptionResult(text: "Hello world", segments: segments, language: "en-US", duration: 1.0)
        let data = try JSONEncoder().encode(result)
        let decoded = try JSONDecoder().decode(AVTranscriptionResult.self, from: data)
        XCTAssertEqual(decoded.text, "Hello world")
        XCTAssertEqual(decoded.segments.count, 2)
        XCTAssertEqual(decoded.language, "en-US")
        XCTAssertEqual(decoded.duration, 1.0)
    }

    // MARK: - AVAudioFormat Enum

    func testAVAudioFormatAllCases() {
        XCTAssertEqual(AVAudioFormat.allCases.count, 4)
    }

    func testAVAudioFormatFileExtensions() {
        for format in AVAudioFormat.allCases {
            XCTAssertEqual(format.fileExtension, format.rawValue,
                           "\(format) fileExtension should match rawValue")
        }
    }

    func testAVAudioFormatDisplayNames() {
        for format in AVAudioFormat.allCases {
            XCTAssertFalse(format.displayName.isEmpty,
                           "\(format) should have a non-empty displayName")
        }
    }

    // MARK: - AVService Real Calls

    func testSupportedFormatsReturnsFour() {
        let formats = service.supportedFormats()
        XCTAssertEqual(formats.count, 4)
        let names = formats.map { $0.format }
        XCTAssertTrue(names.contains("m4a"))
        XCTAssertTrue(names.contains("wav"))
        XCTAssertTrue(names.contains("aiff"))
        XCTAssertTrue(names.contains("caf"))
    }

    func testListInputDevicesReturnsAtLeastOne() async throws {
        let devices = try await service.listInputDevices()
        // Every Mac has at least one audio input device
        XCTAssertFalse(devices.isEmpty, "Should have at least one input device")
    }

    // MARK: - AVService Error Paths

    func testStopRecordingWhenNotRecordingThrows() async {
        do {
            _ = try await service.stopRecording()
            XCTFail("Expected AVError.notRecording")
        } catch let error as AVError {
            guard case .notRecording = error else {
                XCTFail("Expected .notRecording, got \(error)")
                return
            }
        } catch {
            XCTFail("Expected AVError, got \(error)")
        }
    }

    func testTranscribeNonexistentFileThrows() async {
        do {
            _ = try await service.transcribe(filePath: "/nonexistent/audio.m4a", language: nil, timestamps: false, chunkDuration: nil)
            XCTFail("Expected AVError.fileNotFound")
        } catch let error as AVError {
            guard case .fileNotFound = error else {
                XCTFail("Expected .fileNotFound, got \(error)")
                return
            }
        } catch {
            XCTFail("Expected AVError, got \(error)")
        }
    }

    // MARK: - AVError Descriptions

    func testAVErrorDescriptions() {
        let cases: [AVError] = [
            .alreadyRecording,
            .notRecording,
            .recordingFailed("test"),
            .fileNotFound("/tmp/test.m4a"),
            .languageNotSupported("xx-XX"),
            .transcriptionFailed("test reason"),
            .permissionDenied("test denied"),
        ]
        for error in cases {
            XCTAssertNotNil(error.errorDescription, "AVError.\(error) should have errorDescription")
        }
    }
}
