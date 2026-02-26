import AVFoundation
import Foundation
import Speech

public actor AVService: AVServiceProtocol {
    private var recorder: AVAudioRecorder?
    private var recordingStartTime: Date?
    private var recordingOutputPath: String?
    private var recordingFormat: AVAudioFormat?

    public init() {}

    public var isRecording: Bool {
        recorder?.isRecording ?? false
    }

    public func listInputDevices() async throws -> [AVInputDevice] {
        let devices: [AVCaptureDevice]
        if #available(macOS 14.0, *) {
            let discoverySession = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.microphone],
                mediaType: .audio,
                position: .unspecified
            )
            devices = discoverySession.devices
        } else {
            devices = AVCaptureDevice.devices(for: .audio)
        }

        let defaultDevice = AVCaptureDevice.default(for: .audio)

        return devices.map { device in
            AVInputDevice(
                id: device.uniqueID,
                name: device.localizedName,
                isDefault: device.uniqueID == defaultDevice?.uniqueID
            )
        }
    }

    public func startRecording(outputPath: String, format: AVAudioFormat, deviceID: String?) async throws {
        guard recorder == nil || !recorder!.isRecording else {
            throw AVError.alreadyRecording
        }

        let url = URL(fileURLWithPath: outputPath)

        // Ensure parent directory exists
        let parentDir = url.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: parentDir.path) {
            try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)
        }

        let settings = audioSettings(for: format)
        let audioRecorder = try AVFoundation.AVAudioRecorder(url: url, settings: settings)
        audioRecorder.isMeteringEnabled = true

        guard audioRecorder.record() else {
            throw AVError.recordingFailed("Failed to start recording")
        }

        recorder = audioRecorder
        recordingStartTime = Date()
        recordingOutputPath = outputPath
        recordingFormat = format
    }

    public func stopRecording() async throws -> AVRecordingResult {
        guard let audioRecorder = recorder, audioRecorder.isRecording else {
            throw AVError.notRecording
        }

        let duration = audioRecorder.currentTime
        audioRecorder.stop()

        let path = recordingOutputPath ?? audioRecorder.url.path
        let format = recordingFormat ?? .m4a

        // Get file size
        let attrs = try FileManager.default.attributesOfItem(atPath: path)
        let fileSize = attrs[.size] as? Int64 ?? 0

        recorder = nil
        recordingStartTime = nil
        recordingOutputPath = nil
        recordingFormat = nil

        return AVRecordingResult(
            path: path,
            format: format.rawValue,
            duration: duration,
            fileSize: fileSize
        )
    }

    public func transcribe(filePath: String, language: String?, timestamps: Bool, chunkDuration: TimeInterval?) async throws -> AVTranscriptionResult {
        guard FileManager.default.fileExists(atPath: filePath) else {
            throw AVError.fileNotFound(filePath)
        }

        let recognizer: SFSpeechRecognizer
        if let language = language {
            guard let locale = Locale(identifier: language) as Locale?,
                  let r = SFSpeechRecognizer(locale: locale) else {
                throw AVError.languageNotSupported(language)
            }
            recognizer = r
        } else {
            guard let r = SFSpeechRecognizer() else {
                throw AVError.transcriptionFailed("Speech recognizer unavailable")
            }
            recognizer = r
        }

        guard recognizer.isAvailable else {
            throw AVError.transcriptionFailed("Speech recognizer not available")
        }

        // Request authorization
        let authStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        guard authStatus == .authorized else {
            throw AVError.permissionDenied("Speech recognition access denied")
        }

        let url = URL(fileURLWithPath: filePath)

        // Get audio duration
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration).seconds

        let maxChunkDuration = chunkDuration ?? 3300 // 55 minutes default

        if duration > maxChunkDuration {
            return try await transcribeChunked(
                url: url,
                recognizer: recognizer,
                totalDuration: duration,
                chunkDuration: maxChunkDuration,
                timestamps: timestamps,
                language: language
            )
        }

        return try await transcribeSingle(
            url: url,
            recognizer: recognizer,
            duration: duration,
            timestamps: timestamps,
            language: language
        )
    }

    public nonisolated func supportedFormats() -> [AVFormatInfo] {
        AVAudioFormat.allCases.map { format in
            AVFormatInfo(
                format: format.rawValue,
                fileExtension: format.fileExtension,
                displayName: format.displayName
            )
        }
    }

    // MARK: - Private

    private func audioSettings(for format: AVAudioFormat) -> [String: Any] {
        switch format {
        case .m4a:
            return [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            ]
        case .wav:
            return [
                AVFormatIDKey: Int(kAudioFormatLinearPCM),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsFloatKey: false,
            ]
        case .aiff:
            return [
                AVFormatIDKey: Int(kAudioFormatLinearPCM),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsBigEndianKey: true,
            ]
        case .caf:
            return [
                AVFormatIDKey: Int(kAudioFormatLinearPCM),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsFloatKey: false,
            ]
        }
    }

    private func transcribeSingle(url: URL, recognizer: SFSpeechRecognizer, duration: Double, timestamps: Bool, language: String?) async throws -> AVTranscriptionResult {
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false
        request.taskHint = .dictation

        let result: SFSpeechRecognitionResult = try await withUnsafeThrowingContinuation { continuation in
            let lock = NSLock()
            var hasResumed = false
            recognizer.recognitionTask(with: request) { result, error in
                lock.lock()
                guard !hasResumed else {
                    lock.unlock()
                    return
                }
                if let result = result, result.isFinal {
                    hasResumed = true
                    lock.unlock()
                    continuation.resume(returning: result)
                } else if let error = error {
                    hasResumed = true
                    lock.unlock()
                    let nsError = error as NSError
                    if nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 1110 {
                        continuation.resume(throwing: AVError.transcriptionFailed(
                            "No speech detected in audio. The recording may be too quiet, too short, or contain only background noise."
                        ))
                    } else {
                        continuation.resume(throwing: error)
                    }
                } else {
                    lock.unlock()
                }
            }
        }

        var segments: [AVTranscriptionSegment] = []
        if timestamps {
            segments = result.bestTranscription.segments.map { segment in
                AVTranscriptionSegment(
                    text: segment.substring,
                    timestamp: segment.timestamp,
                    duration: segment.duration,
                    confidence: segment.confidence
                )
            }
        }

        return AVTranscriptionResult(
            text: result.bestTranscription.formattedString,
            segments: segments,
            language: language ?? recognizer.locale.identifier,
            duration: duration
        )
    }

    private func transcribeChunked(url: URL, recognizer: SFSpeechRecognizer, totalDuration: Double, chunkDuration: TimeInterval, timestamps: Bool, language: String?) async throws -> AVTranscriptionResult {
        var allText = ""
        var allSegments: [AVTranscriptionSegment] = []
        var offset: TimeInterval = 0

        while offset < totalDuration {
            let chunkEnd = min(offset + chunkDuration, totalDuration)

            // Export chunk using AVAssetExportSession
            let chunkURL = try await exportChunk(from: url, start: offset, end: chunkEnd)
            defer { try? FileManager.default.removeItem(at: chunkURL) }

            let chunkResult = try await transcribeSingle(
                url: chunkURL,
                recognizer: recognizer,
                duration: chunkEnd - offset,
                timestamps: timestamps,
                language: language
            )

            if !allText.isEmpty { allText += " " }
            allText += chunkResult.text

            if timestamps {
                let offsetSegments = chunkResult.segments.map { segment in
                    AVTranscriptionSegment(
                        text: segment.text,
                        timestamp: segment.timestamp + offset,
                        duration: segment.duration,
                        confidence: segment.confidence
                    )
                }
                allSegments.append(contentsOf: offsetSegments)
            }

            offset = chunkEnd
        }

        return AVTranscriptionResult(
            text: allText,
            segments: allSegments,
            language: language ?? recognizer.locale.identifier,
            duration: totalDuration
        )
    }

    private func exportChunk(from url: URL, start: TimeInterval, end: TimeInterval) async throws -> URL {
        let asset = AVURLAsset(url: url)
        let timeRange = CMTimeRange(
            start: CMTime(seconds: start, preferredTimescale: 44100),
            end: CMTime(seconds: end, preferredTimescale: 44100)
        )

        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            throw AVError.transcriptionFailed("Failed to create export session for chunking")
        }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")

        exportSession.outputURL = tempURL
        exportSession.outputFileType = .m4a
        exportSession.timeRange = timeRange

        await exportSession.export()

        guard exportSession.status == .completed else {
            let errorMsg = exportSession.error?.localizedDescription ?? "Unknown export error"
            throw AVError.transcriptionFailed("Chunk export failed: \(errorMsg)")
        }

        return tempURL
    }
}

public enum AVError: LocalizedError {
    case alreadyRecording
    case notRecording
    case recordingFailed(String)
    case fileNotFound(String)
    case languageNotSupported(String)
    case transcriptionFailed(String)
    case permissionDenied(String)

    public var errorDescription: String? {
        switch self {
        case .alreadyRecording:
            return "Already recording"
        case .notRecording:
            return "Not currently recording"
        case .recordingFailed(let reason):
            return "Recording failed: \(reason)"
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .languageNotSupported(let lang):
            return "Language not supported: \(lang)"
        case .transcriptionFailed(let reason):
            return "Transcription failed: \(reason)"
        case .permissionDenied(let reason):
            return reason
        }
    }
}
