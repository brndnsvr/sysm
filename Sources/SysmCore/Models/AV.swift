import Foundation

public struct AVInputDevice: Codable, Sendable {
    public let id: String
    public let name: String
    public let isDefault: Bool

    public init(id: String, name: String, isDefault: Bool) {
        self.id = id
        self.name = name
        self.isDefault = isDefault
    }
}

public enum AVAudioFormat: String, Codable, Sendable, CaseIterable {
    case m4a
    case wav
    case aiff
    case caf

    public var fileExtension: String { rawValue }

    public var displayName: String {
        switch self {
        case .m4a: return "AAC (M4A)"
        case .wav: return "WAV (PCM)"
        case .aiff: return "AIFF"
        case .caf: return "Core Audio Format"
        }
    }
}

public struct AVFormatInfo: Codable, Sendable {
    public let format: String
    public let fileExtension: String
    public let displayName: String

    public init(format: String, fileExtension: String, displayName: String) {
        self.format = format
        self.fileExtension = fileExtension
        self.displayName = displayName
    }
}

public struct AVRecordingResult: Codable, Sendable {
    public let path: String
    public let format: String
    public let duration: Double
    public let fileSize: Int64

    public init(path: String, format: String, duration: Double, fileSize: Int64) {
        self.path = path
        self.format = format
        self.duration = duration
        self.fileSize = fileSize
    }
}

public struct AVTranscriptionSegment: Codable, Sendable {
    public let text: String
    public let timestamp: Double
    public let duration: Double
    public let confidence: Float

    public init(text: String, timestamp: Double, duration: Double, confidence: Float) {
        self.text = text
        self.timestamp = timestamp
        self.duration = duration
        self.confidence = confidence
    }
}

public struct AVTranscriptionResult: Codable, Sendable {
    public let text: String
    public let segments: [AVTranscriptionSegment]
    public let language: String?
    public let duration: Double

    public init(text: String, segments: [AVTranscriptionSegment], language: String?, duration: Double) {
        self.text = text
        self.segments = segments
        self.language = language
        self.duration = duration
    }
}
