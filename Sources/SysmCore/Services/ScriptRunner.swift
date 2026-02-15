import Foundation

public struct ScriptRunner: ScriptRunnerProtocol {

    public init() {}

    // MARK: - Types

    public enum ScriptType: String, CaseIterable {
        case bash
        case zsh
        case fish
        case python
        case python3
        case applescript
        case osascript
        case swift

        var interpreter: String {
            switch self {
            case .bash: return "/bin/bash"
            case .zsh: return "/bin/zsh"
            case .fish: return "/opt/homebrew/bin/fish"
            case .python, .python3: return "/usr/bin/env python3"
            case .applescript, .osascript: return "/usr/bin/osascript"
            case .swift: return "/usr/bin/swift"
            }
        }

        static func fromExtension(_ ext: String) -> ScriptType? {
            switch ext.lowercased() {
            case "sh", "bash": return .bash
            case "zsh": return .zsh
            case "fish": return .fish
            case "py": return .python3
            case "scpt", "applescript": return .applescript
            case "swift": return .swift
            default: return nil
            }
        }

        static func fromShebang(_ shebang: String) -> ScriptType? {
            let lower = shebang.lowercased()
            if lower.contains("bash") { return .bash }
            if lower.contains("zsh") { return .zsh }
            if lower.contains("fish") { return .fish }
            if lower.contains("python3") || lower.contains("python") { return .python3 }
            if lower.contains("osascript") { return .applescript }
            if lower.contains("swift") { return .swift }
            return nil
        }
    }

    public struct ExecutionResult: Codable {
        public let exitCode: Int32
        public let stdout: String
        public let stderr: String
        public let duration: Double  // seconds
        public let scriptType: String

        public var success: Bool { exitCode == 0 }

        public func formatted() -> String {
            var output = ""
            if !stdout.isEmpty {
                output += stdout
            }
            if !stderr.isEmpty {
                if !output.isEmpty { output += "\n" }
                output += "stderr: \(stderr)"
            }
            if !success {
                output += "\nExit code: \(exitCode)"
            }
            return output.isEmpty ? "(no output)" : output
        }
    }

    public enum ScriptError: LocalizedError {
        case fileNotFound(String)
        case executionFailed(String)
        case timeout
        case unknownScriptType(String)
        case interpreterNotFound(String)

        public var errorDescription: String? {
            switch self {
            case .fileNotFound(let path):
                return "Script not found: \(path)"
            case .executionFailed(let message):
                return "Execution failed: \(message)"
            case .timeout:
                return "Script execution timed out"
            case .unknownScriptType(let ext):
                return "Unknown script type: \(ext). Use --shell, --python, or --applescript"
            case .interpreterNotFound(let interpreter):
                return "Interpreter not found: \(interpreter)"
            }
        }
    }

    // MARK: - Execution

    /// Run a script file
    public func runFile(
        path: String,
        args: [String] = [],
        scriptType: ScriptType? = nil,
        timeout: TimeInterval = 300,
        env: [String: String] = [:]
    ) throws -> ExecutionResult {
        let url = URL(fileURLWithPath: path)

        guard FileManager.default.fileExists(atPath: path) else {
            throw ScriptError.fileNotFound(path)
        }

        // Detect script type
        let detectedType: ScriptType
        if let forced = scriptType {
            detectedType = forced
        } else if let fromExt = ScriptType.fromExtension(url.pathExtension) {
            detectedType = fromExt
        } else if let shebang = try? readShebang(path: path), let fromShebang = ScriptType.fromShebang(shebang) {
            detectedType = fromShebang
        } else {
            throw ScriptError.unknownScriptType(url.pathExtension)
        }

        return try execute(
            interpreter: detectedType.interpreter,
            script: path,
            args: args,
            timeout: timeout,
            env: env,
            scriptType: detectedType
        )
    }

    /// Run inline code
    public func runCode(
        code: String,
        scriptType: ScriptType,
        args: [String] = [],
        timeout: TimeInterval = 300,
        env: [String: String] = [:]
    ) throws -> ExecutionResult {
        // Write code to temp file
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent("sysm-exec-\(UUID().uuidString)")

        var scriptPath = tempFile.path
        switch scriptType {
        case .bash, .zsh, .fish:
            scriptPath += ".sh"
        case .python, .python3:
            scriptPath += ".py"
        case .applescript, .osascript:
            scriptPath += ".scpt"
        case .swift:
            scriptPath += ".swift"
        }

        try code.write(toFile: scriptPath, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(atPath: scriptPath) }

        return try execute(
            interpreter: scriptType.interpreter,
            script: scriptPath,
            args: args,
            timeout: timeout,
            env: env,
            scriptType: scriptType
        )
    }

    // MARK: - Private

    private func execute(
        interpreter: String,
        script: String,
        args: [String],
        timeout: TimeInterval,
        env: [String: String],
        scriptType: ScriptType
    ) throws -> ExecutionResult {
        let startTime = Date()

        let task = Process()

        // Handle interpreters with spaces (like "/usr/bin/env python3")
        let interpreterParts = interpreter.split(separator: " ").map(String.init)
        if interpreterParts.count > 1 {
            task.executableURL = URL(fileURLWithPath: interpreterParts[0])
            task.arguments = Array(interpreterParts.dropFirst()) + [script] + args
        } else {
            task.executableURL = URL(fileURLWithPath: interpreter)
            task.arguments = [script] + args
        }

        // Set up environment
        var environment = ProcessInfo.processInfo.environment
        environment["SYSM_VERSION"] = "1.0.0"
        environment["SYSM_SCRIPT_TYPE"] = scriptType.rawValue
        for (key, value) in env {
            environment[key] = value
        }
        task.environment = environment

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = errorPipe

        // Timeout handling with thread-safe flag
        let timedOutLock = NSLock()
        var timedOut = false
        let timeoutWorkItem = DispatchWorkItem {
            timedOutLock.lock()
            timedOut = true
            timedOutLock.unlock()
            task.terminate()
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + timeout, execute: timeoutWorkItem)

        do {
            try task.run()
        } catch {
            timeoutWorkItem.cancel()
            throw ScriptError.executionFailed(error.localizedDescription)
        }

        // Read stdout and stderr concurrently BEFORE waitUntilExit to avoid
        // pipe buffer deadlocks. If a pipe's buffer fills (~64KB), the process
        // blocks until the buffer is drained. Reading after waitUntilExit would
        // deadlock since waitUntilExit can't return while the process is blocked.
        var outputData = Data()
        var errorData = Data()
        let readGroup = DispatchGroup()

        readGroup.enter()
        DispatchQueue.global().async {
            outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            readGroup.leave()
        }
        errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        readGroup.wait()

        task.waitUntilExit()
        timeoutWorkItem.cancel()

        timedOutLock.lock()
        let didTimeout = timedOut
        timedOutLock.unlock()

        if didTimeout {
            throw ScriptError.timeout
        }

        let stdout = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let stderr = String(data: errorData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        let duration = Date().timeIntervalSince(startTime)

        return ExecutionResult(
            exitCode: task.terminationStatus,
            stdout: stdout,
            stderr: stderr,
            duration: duration,
            scriptType: scriptType.rawValue
        )
    }

    private func readShebang(path: String) throws -> String? {
        guard let handle = FileHandle(forReadingAtPath: path) else { return nil }
        defer { try? handle.close() }

        let data = handle.readData(ofLength: 256)
        guard let content = String(data: data, encoding: .utf8) else { return nil }

        let lines = content.components(separatedBy: .newlines)
        guard let firstLine = lines.first, firstLine.hasPrefix("#!") else { return nil }

        return firstLine
    }
}
