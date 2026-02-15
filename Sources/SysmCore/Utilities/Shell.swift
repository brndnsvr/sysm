import Foundation

/// Centralized utility for executing shell commands with consistent error handling.
///
/// `Shell` provides a unified API for running external processes, replacing the
/// boilerplate Process setup scattered throughout the codebase. It supports stdin,
/// timeout handling, and custom environment variables.
///
/// ## Usage
/// ```swift
/// // Simple execution - returns stdout, throws on non-zero exit
/// let output = try Shell.run("/usr/bin/mdfind", args: ["kMDItemUserTags == 'important'"])
///
/// // Full control with Result struct
/// let result = try Shell.execute("/usr/bin/shortcuts", args: ["list"])
/// if result.exitCode == 0 {
///     print(result.stdout)
/// }
/// ```
public enum Shell {

    // MARK: - Result Type

    /// The result of a shell command execution.
    public struct Result {
        /// The exit code of the process.
        let exitCode: Int32
        /// Standard output captured from the process.
        let stdout: String
        /// Standard error captured from the process.
        let stderr: String

        /// Whether the command succeeded (exit code 0).
        var succeeded: Bool { exitCode == 0 }
    }

    // MARK: - Errors

    /// Errors that can occur during shell command execution.
    public enum Error: LocalizedError {
        /// The specified executable was not found.
        case commandNotFound(String)
        /// The command failed with a non-zero exit code.
        case executionFailed(exitCode: Int32, stderr: String)
        /// The command exceeded the specified timeout.
        case timeout(TimeInterval)
        /// Failed to launch the process.
        case launchFailed(String)

        public var errorDescription: String? {
            switch self {
            case .commandNotFound(let path):
                return "Command not found: \(path)"
            case .executionFailed(let code, let stderr):
                if stderr.isEmpty {
                    return "Command failed with exit code \(code)"
                }
                return "Command failed with exit code \(code): \(stderr)"
            case .timeout(let seconds):
                return "Command timed out after \(Int(seconds)) seconds"
            case .launchFailed(let reason):
                return "Failed to launch command: \(reason)"
            }
        }
    }

    // MARK: - Simple Execution

    /// Runs a command and returns stdout. Throws on non-zero exit code.
    ///
    /// - Parameters:
    ///   - executable: Path to the executable.
    ///   - args: Command arguments.
    ///   - stdin: Optional input to write to the process's stdin.
    ///   - timeout: Optional timeout in seconds.
    ///   - environment: Optional environment variables to add/override.
    ///   - workingDirectory: Optional working directory for the process.
    /// - Returns: The trimmed stdout output.
    /// - Throws: `Shell.Error` if the command fails or times out.
    public static func run(
        _ executable: String,
        args: [String] = [],
        stdin: String? = nil,
        timeout: TimeInterval? = nil,
        environment: [String: String]? = nil,
        workingDirectory: String? = nil
    ) throws -> String {
        let result = try execute(
            executable,
            args: args,
            stdin: stdin,
            timeout: timeout,
            environment: environment,
            workingDirectory: workingDirectory
        )

        guard result.exitCode == 0 else {
            throw Error.executionFailed(exitCode: result.exitCode, stderr: result.stderr)
        }

        return result.stdout
    }

    // MARK: - Full Execution

    /// Executes a command and returns a Result struct with full details.
    ///
    /// Unlike `run()`, this method does not throw on non-zero exit codes,
    /// allowing the caller to handle failures manually.
    ///
    /// - Parameters:
    ///   - executable: Path to the executable.
    ///   - args: Command arguments.
    ///   - stdin: Optional input to write to the process's stdin.
    ///   - timeout: Optional timeout in seconds.
    ///   - environment: Optional environment variables to add/override.
    ///   - workingDirectory: Optional working directory for the process.
    /// - Returns: A `Result` containing exit code, stdout, and stderr.
    /// - Throws: `Shell.Error` for command not found, launch failure, or timeout.
    public static func execute(
        _ executable: String,
        args: [String] = [],
        stdin: String? = nil,
        timeout: TimeInterval? = nil,
        environment: [String: String]? = nil,
        workingDirectory: String? = nil
    ) throws -> Result {
        // Verify executable exists
        guard FileManager.default.fileExists(atPath: executable) else {
            throw Error.commandNotFound(executable)
        }

        let task = Process()
        task.executableURL = URL(fileURLWithPath: executable)
        task.arguments = args

        // Set environment if provided
        if let environment = environment {
            var env = ProcessInfo.processInfo.environment
            for (key, value) in environment {
                env[key] = value
            }
            task.environment = env
        }

        // Set working directory if provided
        if let workingDirectory = workingDirectory {
            task.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)
        }

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = errorPipe

        // Handle stdin if provided
        let inputPipe: Pipe?
        if stdin != nil {
            inputPipe = Pipe()
            task.standardInput = inputPipe
        } else {
            inputPipe = nil
        }

        // Timeout handling with thread-safe flag
        let timedOutLock = NSLock()
        var timedOut = false
        var timeoutWorkItem: DispatchWorkItem?
        if let timeout = timeout {
            timeoutWorkItem = DispatchWorkItem {
                timedOutLock.lock()
                timedOut = true
                timedOutLock.unlock()
                task.terminate()
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + timeout, execute: timeoutWorkItem!)
        }

        // Launch process
        do {
            try task.run()
        } catch {
            timeoutWorkItem?.cancel()
            throw Error.launchFailed(error.localizedDescription)
        }

        // Write stdin and close
        if let inputPipe = inputPipe, let stdinData = stdin?.data(using: .utf8) {
            inputPipe.fileHandleForWriting.write(stdinData)
            inputPipe.fileHandleForWriting.closeFile()
        }

        // Read stdout and stderr concurrently to avoid pipe buffer deadlocks.
        // If both pipes fill their buffer (~64KB), sequential reads would deadlock.
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
        timeoutWorkItem?.cancel()

        timedOutLock.lock()
        let didTimeout = timedOut
        timedOutLock.unlock()

        if didTimeout {
            throw Error.timeout(timeout ?? 0)
        }

        let stdout = String(data: outputData, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let stderr = String(data: errorData, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        return Result(exitCode: task.terminationStatus, stdout: stdout, stderr: stderr)
    }
}
