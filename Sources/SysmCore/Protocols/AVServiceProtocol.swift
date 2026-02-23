import Foundation

public protocol AVServiceProtocol: Sendable {
    func listInputDevices() async throws -> [AVInputDevice]
    func startRecording(outputPath: String, format: AVAudioFormat, deviceID: String?) async throws
    func stopRecording() async throws -> AVRecordingResult
    var isRecording: Bool { get async }
    func transcribe(filePath: String, language: String?, timestamps: Bool, chunkDuration: TimeInterval?) async throws -> AVTranscriptionResult
    func supportedFormats() -> [AVFormatInfo]
}
