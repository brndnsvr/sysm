import ArgumentParser
import Dispatch
import Foundation
import SysmCore

struct AVRecord: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "record",
        abstract: "Record audio from a device (shortcuts: teams, mic, all)"
    )

    private static let deviceAliases: [String: String] = [
        "teams": "MSLoopbackDriverDevice_UID",
        "mic": "BuiltInMicrophoneDevice",
        "all": "BlackHole2ch_UID",
    ]

    @Argument(help: "Device shortcut: teams, mic, all")
    var shortcut: String?

    @Option(name: .shortAndLong, help: "Output file path")
    var output: String?

    @Option(name: .long, help: "Audio format (m4a, wav, aiff, caf)")
    var format: String = "m4a"

    @Option(name: .long, help: "Recording duration in seconds (omit for manual stop with Ctrl+C)")
    var duration: Double?

    @Option(name: .long, help: "Input device ID")
    var device: String?

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        guard let audioFormat = AVAudioFormat(rawValue: format) else {
            throw ValidationError("Unsupported format '\(format)'. Use: m4a, wav, aiff, caf")
        }

        // Resolve device: shortcut takes precedence over --device
        let resolvedDevice: String?
        if let shortcut = shortcut {
            guard let mapped = Self.deviceAliases[shortcut] else {
                let valid = Self.deviceAliases.keys.sorted().joined(separator: ", ")
                throw ValidationError("Unknown shortcut '\(shortcut)'. Use: \(valid)")
            }
            resolvedDevice = mapped
        } else {
            resolvedDevice = device
        }

        let outputPath = output ?? defaultOutputPath(format: audioFormat)
        let service = Services.av()

        try await service.startRecording(outputPath: outputPath, format: audioFormat, deviceID: resolvedDevice)

        if let duration = duration {
            // Timed recording
            if !json {
                print("Recording for \(Int(duration))s to \(outputPath)...")
            }
            try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
        } else {
            // Manual stop via Ctrl+C
            if !json {
                print("Recording to \(outputPath)... Press Ctrl+C to stop.")
            }

            let semaphore = DispatchSemaphore(value: 0)
            let signalSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
            signal(SIGINT, SIG_IGN)
            signalSource.setEventHandler {
                semaphore.signal()
            }
            signalSource.resume()

            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                DispatchQueue.global().async {
                    semaphore.wait()
                    continuation.resume()
                }
            }

            signalSource.cancel()
        }

        let result = try await service.stopRecording()

        if json {
            try OutputFormatter.printJSON(result)
        } else {
            let size = OutputFormatter.formatFileSize(result.fileSize)
            let dur = String(format: "%.1f", result.duration)
            print("\nRecording saved:")
            print("  Path: \(result.path)")
            print("  Format: \(result.format)")
            print("  Duration: \(dur)s")
            print("  Size: \(size)")
        }
    }

    private func defaultOutputPath(format: AVAudioFormat) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let timestamp = formatter.string(from: Date())
        let dir = FileManager.default.currentDirectoryPath
        return "\(dir)/recording_\(timestamp).\(format.fileExtension)"
    }
}
