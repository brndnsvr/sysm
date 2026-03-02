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

    @Option(name: .long, help: "Recording duration in seconds (omit for interactive mode)")
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
            // Timed recording — no interactive prompt
            if !json {
                print("Recording for \(Int(duration))s to \(outputPath)...")
            }
            try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
        } else if json {
            // JSON mode — block on SIGINT for programmatic/scripted use
            await waitForSIGINT()
        } else {
            // Interactive mode — readline prompt loop
            await interactiveLoop(service: service, outputPath: outputPath)
        }

        let result = try await service.stopRecording()

        if json {
            try OutputFormatter.printJSON(result)
        } else {
            printResult(result)
        }
    }

    // MARK: - Interactive Mode

    private func interactiveLoop(service: AVServiceProtocol, outputPath: String) async {
        print("Recording to \(outputPath)")
        print("")
        print("Commands: status, pause, resume, stop (or help)")

        // Install SIGINT handler that sets a flag instead of killing the process
        let sigintReceived = UnsafeMutablePointer<Bool>.allocate(capacity: 1)
        sigintReceived.initialize(to: false)
        defer {
            sigintReceived.deinitialize(count: 1)
            sigintReceived.deallocate()
        }

        let oldHandler = signal(SIGINT, SIG_IGN)
        let signalSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: .global())
        signalSource.setEventHandler {
            sigintReceived.pointee = true
        }
        signalSource.resume()

        while true {
            let input = await CLI.readLineAsync(prompt: "recording> ")

            // nil means EOF (Ctrl+D) or SIGINT interrupted the read
            guard let input = input else {
                print("")
                break
            }

            // Check if SIGINT was received
            if sigintReceived.pointee {
                print("")
                break
            }

            let command = input.trimmingCharacters(in: .whitespaces).lowercased()

            if command.isEmpty {
                continue
            }

            switch command {
            case "status", "s":
                await printStatus(service: service)
            case "pause", "p":
                await pauseRecording(service: service)
            case "resume", "r":
                await resumeRecording(service: service)
            case "stop", "end", "q":
                break
            case "help", "?":
                printHelp()
                continue
            default:
                print("Unknown command. Type 'help' for options.")
                continue
            }

            // If we hit stop/end/q, break out of the while loop
            if command == "stop" || command == "end" || command == "q" {
                break
            }
        }

        signalSource.cancel()
        signal(SIGINT, oldHandler)
    }

    private func printStatus(service: AVServiceProtocol) async {
        do {
            let status = try await service.recordingStatus()
            let duration = OutputFormatter.formatDuration(status.elapsedTime)
            let size = OutputFormatter.formatFileSize(status.currentFileSize)
            let state = status.isPaused ? "Paused" : "Recording"
            print("  File:     \(status.filePath)")
            print("  Format:   \(status.format)")
            print("  Duration: \(duration)")
            print("  Size:     \(size)")
            print("  State:    \(state)")
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }

    private func pauseRecording(service: AVServiceProtocol) async {
        do {
            try await service.pauseRecording()
            print("Recording paused.")
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }

    private func resumeRecording(service: AVServiceProtocol) async {
        do {
            try await service.resumeRecording()
            print("Recording resumed.")
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }

    private func printHelp() {
        print("  status (s)  — Show recording status")
        print("  pause  (p)  — Pause recording")
        print("  resume (r)  — Resume recording")
        print("  stop   (q)  — Stop and save recording")
        print("  help   (?)  — Show this help")
    }

    // MARK: - SIGINT Wait (JSON mode)

    private func waitForSIGINT() async {
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

    // MARK: - Output

    private func printResult(_ result: AVRecordingResult) {
        let size = OutputFormatter.formatFileSize(result.fileSize)
        let dur = OutputFormatter.formatDuration(result.duration)
        print("")
        print("Recording saved:")
        print("  Path:     \(result.path)")
        print("  Format:   \(result.format)")
        print("  Duration: \(dur)")
        print("  Size:     \(size)")
    }

    private func defaultOutputPath(format: AVAudioFormat) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let timestamp = formatter.string(from: Date())
        let dir = FileManager.default.currentDirectoryPath
        return "\(dir)/recording_\(timestamp).\(format.fileExtension)"
    }
}
